// SDKConfirmTool.cpp
//
// This is a simple console application that demonstrates how to connect to a Photron camera and download high-speed video data.
// The application uses the Photron SDK to connect to a camera, set it to playback mode, and download video data in MRAW and CIHX formats.

//#define WINAPI __stdcall
#define PDC_API __cdecl

#include "stdafx.h"
//#include "./../../PDCLIB/Include/PDCLIB.h"
#include "PDCLIB.h"
#include <Windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include <fstream>
#include <vector>

#include <chrono>
#include <iomanip>
#include <sstream>
#include <filesystem>

#include <thread>
#include <atomic>
#include <conio.h> // For _kbhit() and _getch()

#include <locale>
#include <codecvt>

#include <nlohmann/json.hpp>
using json = nlohmann::json;

namespace fs = std::filesystem;

#pragma comment(lib, "PDCLIB.lib")

// Const
#define MAX_LENGTH_IP_STRING	256	// max length xxx.xxx.xxx.xxx
#define MAX_COUNT_IP_ELEMENT	4	// max count 1.2.3.4

// Declaration
static BOOL Initialize();
bool ConnectToCamera(const std::string& ipAddress, bool autoDetect);
bool RecordVideo(unsigned long nDeviceNo, unsigned long nChildNo, unsigned long nRate, unsigned long nFrames, std::atomic<bool>& exit_requested);
void SaveMRAW(unsigned long nDeviceNo, unsigned long nChildNo, const wchar_t* mrawPath, long nDownloadFrame);
void SaveCIHX(unsigned long nDeviceNo, unsigned long nChildNo, const char* cihxPath, long nDownloadFrame);
void DownloadHighSpeedVideo(unsigned long nDeviceNo, unsigned long nChildNo, const wchar_t* mrawPath, const char* cihxPath, long nTotalFrame);
unsigned long ConvertIpStringToInt(const std::string& ip);

static int SpliString(LPTSTR lpszString, LPCTSTR lpszDelimiter, LPTSTR lpszStringList[]);
static BOOL IsNumber(LPCTSTR lpszString);
static BOOL Finalize();

int GetNextAvailableIndex(const std::string& directory, const std::string& prefix, const std::string& extension, int padding = 4);
json LoadLog(const std::string& logPath);
void SaveLog(const std::string& logPath, const json& j);
void UpdateLogStatus(const std::string& logPath, const std::string& caseName, const std::string& newStatus);

// Global variable
BOOL g_bOpen = FALSE;			// TRUE:Open FALSE:NotOpen
unsigned long g_nDeviceNo = 0;	// Device No
unsigned long g_nChildNo = 0;	// Child No

// Structure to hold camera settings
struct PIVSettings {
	int acquisition_freq_Hz;
	int delta_t_us;
	int pulse_width_us;
	int nDoubleFrames;
	bool ext_trigger;
};

struct COMSettings {
	std::string bnc_connection;
	std::string laser_connection;
	std::string camOne_connection;
	std::string camTwo_connection;
};

struct Config {
	std::string root_dir;
	std::string raw_PIV_dir;
	std::string proc_PIV_dir;
	std::string log_path;
	PIVSettings piv;
	COMSettings com;
};

// Function to read config
Config load_config(const std::string& filepath) {
	std::ifstream file(filepath);
	if (!file.is_open()) {
		throw std::runtime_error("Failed to open config file: " + filepath);
	}

	nlohmann::json j;
	file >> j;

	Config cfg;
	cfg.root_dir = j["root_dir"];
	cfg.raw_PIV_dir = j["raw_PIV_dir"];
	cfg.proc_PIV_dir = j["proc_PIV_dir"];
	cfg.log_path = j["log_path"];

	const auto& p = j["PIV_settings"];
	cfg.piv.acquisition_freq_Hz = p["acquisition_freq_Hz"];
	cfg.piv.delta_t_us = p["delta_t_us"];
	cfg.piv.pulse_width_us = p["pulse_width_us"];
	cfg.piv.nDoubleFrames = p.value("nDoubleFrames", 0); // Provide a default value of 0 if the field is missing
	cfg.piv.ext_trigger = p["ext_trigger"];

	const auto& c = j["COM_settings"];
	cfg.com.bnc_connection = c["bnc_connection"];
	cfg.com.laser_connection = c["laser_connection"];
	cfg.com.camOne_connection = c["camOne_connection"];
	cfg.com.camTwo_connection = c["camTwo_connection"];

	return cfg;
}

// Function to generate timestamp string
std::string GetTimestamp() {
	auto now = std::chrono::system_clock::now();
	std::time_t now_time = std::chrono::system_clock::to_time_t(now);
	std::stringstream ss;
	ss << std::put_time(std::localtime(&now_time), "%Y%m%d_%H%M%S");
	return ss.str();
}

// Convert std::string to std::wstring
std::wstring StringToWString(const std::string& str) {
	std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
	return converter.from_bytes(str);
}

// Entry point
int _tmain(int argc, _TCHAR* argv[])
{
	_tsetlocale(LC_ALL, _T(".ACP"));

	if (argc < 2) {
		std::cerr << "Usage: CameraControl.exe <path_to_config.json>\n";
		return -1;
	}

	// Convert _TCHAR* to std::string if needed (Unicode vs ANSI)
	#ifdef _UNICODE
		std::wstring widePath = argv[1];
		std::string configPath(widePath.begin(), widePath.end());
	#else
		std::string configPath = argv[1];
	#endif

	Config cfg;
	try {
		cfg = load_config(configPath);
	}
	catch (const std::exception& e) {
		std::cerr << "Config error: " << e.what() << "\n";
		return -1;
	}

	// Access parameters like this:
	std::cout << "Camera 1 IP: " << cfg.com.camOne_connection << "\n";
	std::cout << "Acquisition Frequency: " << cfg.piv.acquisition_freq_Hz << " Hz\n";

	std::string cameraIP = cfg.com.camOne_connection;  // Replace with the actual camera IP if known (e.g. "192.168.1.10")

	unsigned long nRate = 2*cfg.piv.acquisition_freq_Hz; // Record rate in fps/Hz - x2 because of double frames (e.g. 200 if double frames recorded at 100 Hz)
	unsigned long nFrames = 2*cfg.piv.nDoubleFrames; // Number of frames to record - x2 because of double frames (e.g. 400 if 200 double frames recorded)

	Initialize();

	// Connect to Camera
	std::cout << "\nConnecting to camera at " << cameraIP << "...\n";
	if (!ConnectToCamera(cameraIP, false)) {
		std::cerr << "Failed to connect to camera.\n";
		return -1;
	}
	std::cout << "Connection successful!\n";

	// Use cfg.raw_PIV_dir for where to save the videos
	std::string videoDir = cfg.raw_PIV_dir;
	fs::create_directories(videoDir); // Ensure directory exists

	std::string logPath = cfg.log_path;
	json log = LoadLog(logPath);
	log["status"] = "ready";
	SaveLog(logPath, log);

	std::atomic<bool> exit_requested{ false };

	// Thread that listens for keypresses - this allows the user to exit the recording loop gracefully
	std::thread exit_thread([&exit_requested]() {
		while (true) {
			if (_kbhit() && _getch() == 'q') {
				exit_requested = true;
				break;
			}
			std::this_thread::sleep_for(std::chrono::milliseconds(100));
		}
		});

	std::cout << "Press 'q' to stop recording...\n";

	while (true) {
		if (exit_requested) {
			std::cout << "Exit requested. Finishing current cycle...\n";
		}

		// Get next available index
		int index = GetNextAvailableIndex(videoDir, "ms", ".mraw");

		// Break early if requested and we haven't started recording yet
		if (exit_requested) {
			std::cout << "No new recording will be started.\n";
			break;
		}

		// Build file names
		// (same code as before)
		std::stringstream baseName;
		baseName << "ms" << std::setw(4) << std::setfill('0') << index;
		std::string caseName = baseName.str();
		fs::path mrawFullPath = fs::path(videoDir) / (baseName.str() + ".mraw");
		fs::path cihxFullPath = fs::path(videoDir) / (baseName.str() + ".cihx");
		std::wstring mrawPath = StringToWString(mrawFullPath.string());
		std::string cihxPath = cihxFullPath.string();

		// Log: recording
		log = LoadLog(logPath);
		log["status"] = "recording";
		SaveLog(logPath, log);

		std::cout << "Recording: " << baseName.str() << "\n";

		// Start recording
		bool recorded = RecordVideo(g_nDeviceNo, g_nChildNo, nRate, nFrames, exit_requested);

		// If recording was skipped (e.g. due to 'q'), don't download or log
		if (!recorded) {
			std::cout << "No recording happened. Skipping download and logging.\n";
			break;  // or continue; if you want to check again
		}

		// (continue as before if recording occurred)

		log = LoadLog(logPath);
		log["status"] = "downloading";
		SaveLog(logPath, log);

		DownloadHighSpeedVideo(g_nDeviceNo, g_nChildNo, mrawPath.c_str(), cihxPath.c_str(), nFrames);

		log = LoadLog(logPath);
		log["cases"][caseName] = {
			{"timestamp", GetTimestamp()},
			{"status", "saved"}
		};
		log["n_recorded"] = static_cast<int>(log["cases"].size());
		log["status"] = "ready";
		SaveLog(logPath, log);

		std::cout << "Saved: " << baseName.str() << ".mraw / .cihx\n";

		// If 'q' was pressed during download, break now
		if (exit_requested) {
			std::cout << "Exit requested. Exiting after current recording.\n";
			break;
		}
	}

	Finalize();

	if (exit_thread.joinable()) {
		exit_thread.join();
	}

	_tprintf(_T("Please Input Key..."));
	_fgettc(stdin);

	return 0;
}

// Initial processing
static BOOL Initialize()
{
	unsigned long nRet = 0;
	unsigned long nErrorCode = PDC_SUCCEEDED;

	_tprintf(_T("PDC_Init...\n"));
	nRet = PDC_Init(&nErrorCode);
	if (nRet == PDC_SUCCEEDED)
	{
		_tprintf(_T("\tOK\n"));
		return TRUE;
	}
	else
	{
		_tprintf(_T("\tNG (Error Code=%u)\n"), nErrorCode);
		return FALSE;
	}
}

bool RecordVideo(unsigned long nDeviceNo, unsigned long nChildNo,
	unsigned long nRate, unsigned long nFrames,
	std::atomic<bool>& exit_requested)
{
	unsigned long nRet;
	unsigned long nStatus;
	unsigned long nErrorCode;

	unsigned long recordingTime = 1.1 * nFrames / nRate * 1000;

	nRet = PDC_SetTriggerMode(nDeviceNo, PDC_TRIGGER_RANDOM_RESET, nRate, nRate, nRate, &nErrorCode);
	if (nRet == PDC_FAILED) {
		printf("PDC_SetTriggerMode Error %d\n", nErrorCode);
		return false;
	}

	nRet = PDC_SetRecordRate(nDeviceNo, nChildNo, nRate, &nErrorCode);
	if (nRet == PDC_FAILED) {
		printf("PDC_SetRecordRate Error %d\n", nErrorCode);
		return false;
	}

	nRet = PDC_SetRecReady(nDeviceNo, &nErrorCode);
	if (nRet == PDC_FAILED) {
		printf("PDC_SetRecReady Error %d\n", nErrorCode);
		return false;
	}

	while (true) {
		nRet = PDC_GetStatus(nDeviceNo, &nStatus, &nErrorCode);
		if (nRet == PDC_FAILED) {
			printf("PDC_GetStatus Error %d\n", nErrorCode);
			return false;
		}
		if (exit_requested) {
			std::cout << "Exit requested before trigger.\n";
			PDC_SetStatus(nDeviceNo, PDC_STATUS_LIVE, &nErrorCode);
			PDC_SetStatus(nDeviceNo, PDC_STATUS_PLAYBACK, &nErrorCode);
			return false;
		}
		if (nStatus == PDC_STATUS_RECREADY || nStatus == PDC_STATUS_REC) {
			std::cout << "Camera in recording mode - Ready to trigger.\n";
			break;
		}
		Sleep(100);
	}

	while (true) {
		nRet = PDC_GetStatus(nDeviceNo, &nStatus, &nErrorCode);
		if (nRet == PDC_FAILED) {
			printf("PDC_GetStatus Error %d\n", nErrorCode);
			return false;
		}
		if (exit_requested) {
			std::cout << "Exit requested before recording triggered.\n";
			PDC_SetStatus(nDeviceNo, PDC_STATUS_LIVE, &nErrorCode);
			PDC_SetStatus(nDeviceNo, PDC_STATUS_PLAYBACK, &nErrorCode);
			return false;
		}
		if (nStatus != PDC_STATUS_RECREADY) {
			std::cout << "Camera recording.\n";
			break;
		}
		Sleep(100);
	}

	Sleep(recordingTime);

	// Cleanly stop recording
	PDC_SetStatus(nDeviceNo, PDC_STATUS_LIVE, &nErrorCode);
	PDC_SetStatus(nDeviceNo, PDC_STATUS_PLAYBACK, &nErrorCode);

	return true; // Recording was completed
}


void DownloadHighSpeedVideo(unsigned long nDeviceNo, unsigned long nChildNo, const wchar_t* mrawPath, const char* cihxPath, long nTotalFrame = -1)
{
	PDC_FRAME_INFO FrameInfo;
	unsigned long nRet, nStatus, nErrorCode;

	// Set camera to playback mode
	nRet = PDC_SetStatus(nDeviceNo, PDC_STATUS_PLAYBACK, &nErrorCode);
	if (nRet == PDC_FAILED) {
		printf("PDC_SetStatus Error %d\n", nErrorCode);
		return;
	}
	do {
		nRet = PDC_GetStatus(nDeviceNo, &nStatus, &nErrorCode);
	} while (nStatus != PDC_STATUS_PLAYBACK);

	printf("In Playback Mode\n\n");

	// Retrieve frame information
	nRet = PDC_GetMemFrameInfo(nDeviceNo, nChildNo, &FrameInfo, &nErrorCode);
	if (nRet == PDC_FAILED) {
		printf("PDC_GetMemFrameInfo Error %d\n", nErrorCode);
		return;
	}
	printf("Frames Captured: %d\n", FrameInfo.m_nRecordedFrames);

	// Determine number of frames to download
	long nDownloadFrame = (nTotalFrame < 0 || nTotalFrame > FrameInfo.m_nRecordedFrames) ? FrameInfo.m_nRecordedFrames : nTotalFrame;
	printf("Downloading %d frames\n", nDownloadFrame);

	// Save MRAW file
	SaveMRAW(nDeviceNo, nChildNo, mrawPath, nDownloadFrame);

	// Save CIHX file
	SaveCIHX(nDeviceNo, nChildNo, cihxPath, nDownloadFrame);
}

void SaveMRAW(unsigned long nDeviceNo, unsigned long nChildNo, const wchar_t* mrawPath, long nDownloadFrame)
{
	unsigned long nErrorCode;
	PDC_MRAWFileSaveOpenEx(nDeviceNo, nChildNo, mrawPath, PDC_MRAW_BITDEPTH_12, nDownloadFrame, PDC_FUNCTION_OFF, &nErrorCode);
	PDC_MRAWFileSaveStartEx(nDeviceNo, nChildNo, 0, nDownloadFrame - 1, &nErrorCode);

	long nSaving, nFrameNum;
	do {
		Sleep(2000);
		PDC_MRAWFileSaveStatusEx(nDeviceNo, nChildNo, &nSaving, &nFrameNum, &nErrorCode);
		printf("SavingFrame: %d\n", nFrameNum);
	} while (nFrameNum != nDownloadFrame);

	PDC_MRAWFileSaveCloseEx(nDeviceNo, nChildNo, &nErrorCode);
}

// TODO: PROPERLY REFACTOR THIS FUNCTION, SEE VERSION BELOW IT
void SaveCIHX(unsigned long nDeviceNo, unsigned long nChildNo, const char* cihxPath, long nDownloadFrame)
{
	unsigned long nRet;
	unsigned long nStatus;
	unsigned long nErrorCode;

	// Save CIHX file
	PDC_ARCHIVE_PARAM Required;
	memset(&Required, 0, sizeof(Required));
	Required.pFileFormat = "Mraw";
	Required.pColorType = PDC_CIH_COLORTYPE_RAW_STR; // PDC_CIH_COLORTYPE_COLOR_STR, PDC_CIH_COLORTYPE_MONO_STR, PDC_CIH_COLORTYPE_RAW_STR, PDC_CIH_COLORTYPE_BAYER_STR
	Required.colorDepth = 12;

	PDC_ARCHIVE_OPTION_META MetaOption[2];

	MetaOption[0].pKey = PDC_CIH_KEY_FRAME_TOTAL;
	char nDownloadFrameStr[20];
	sprintf(nDownloadFrameStr, "%ld", nDownloadFrame);

	MetaOption[0].pValue = nDownloadFrameStr;
	//MetaOption[0].pValue = nDownloadFrame;

	MetaOption[1].pKey = PDC_CIH_KEY_FRAME_START;
	MetaOption[1].pValue = "0";

	PDC_ARCHIVE_OPTION Option;
	Option.type = PDC_ARCHIVE_OPTION_TYPE_META;
	Option.count = 2;
	Option.pOption = &MetaOption;

	PDC_ARCHIVE_HANDLE handle = NULL;

	nRet = PDC_InitCihxSave(&handle, &nErrorCode);

	if (nRet == PDC_FAILED) {
		printf("PDC_InitCihxSave Error %d\n", nErrorCode);
		return;
	}

	nRet = PDC_SaveCihxFromCameraA(handle, cihxPath, nDeviceNo, nChildNo,
		&Required, &Option, 1, &nErrorCode);

	if (nRet == PDC_FAILED) {
		printf("PDC_SaveCihxFromCamera Error %d\n", nErrorCode);
		return;
	}

	PDC_ARCHIVE_DATA_TYPE nDataType;
	unsigned long nProgress;
	PDC_EXPORT_STATUS nExportStatus;
	char ErrorInfo[PDC_MAX_STRING_LENGTH] = { 0 };

	while (1) {
		nRet = PDC_GetCihxSaveStatusA(
			handle,
			&nDataType,
			&nExportStatus,
			&nProgress,
			ErrorInfo,
			&nErrorCode);

		if (nRet == PDC_FAILED) {
			printf("PDC_GetCihxSaveStatus Error %d\n", nErrorCode);
			break;
		}

		if (nExportStatus == PDC_EXPORT_STATUS_COMPLETE) {
			break;
		}
		else if (nExportStatus == PDC_EXPORT_STATUS_ERROR) {
			printf("PDC_GetCihxSaveStatus Error %s\n", ErrorInfo);
			break;
		}

		Sleep(50);
	}

	nRet = PDC_ExitCihxSave(handle, &nErrorCode);

	if (nRet == PDC_FAILED) {
		printf("PDC_ExitCihxSave Error %d\n", nErrorCode);
	}
}

/*
void SaveCIHX(unsigned long nDeviceNo, unsigned long nChildNo, const char* cihxPath, long nDownloadFrame)
{
	PDC_ARCHIVE_PARAM Required = { 0 };
	Required.pFileFormat = "Mraw";
	Required.pColorType = PDC_CIH_COLORTYPE_RAW_STR;
	Required.colorDepth = 12;

	PDC_ARCHIVE_OPTION_META MetaOption[2];
	char nDownloadFrameStr[20];
	sprintf(nDownloadFrameStr, "%ld", nDownloadFrame);
	MetaOption[0].pKey = PDC_CIH_KEY_FRAME_TOTAL;
	MetaOption[0].pValue = nDownloadFrameStr;
	MetaOption[1].pKey = PDC_CIH_KEY_FRAME_START;
	MetaOption[1].pValue = "0";

	PDC_ARCHIVE_OPTION Option = { PDC_ARCHIVE_OPTION_TYPE_META, MetaOption, 2 };
	PDC_ARCHIVE_HANDLE handle = NULL;
	unsigned long nErrorCode;
	PDC_InitCihxSave(&handle, &nErrorCode);
	PDC_SaveCihxFromCameraA(handle, cihxPath, nDeviceNo, nChildNo, &Required, &Option, 1, &nErrorCode);

	unsigned long nProgress;
	PDC_EXPORT_STATUS nExportStatus;
	char ErrorInfo[PDC_MAX_STRING_LENGTH] = { 0 };

	int attempts = 0;
	int max_attempts = 200; // Failsafe to prevent infinite looping

	do {
		printf("Checking before calling PDC_GetCihxSaveStatusA: Handle = %d\n", handle);

		PDC_GetCihxSaveStatusA(handle, NULL, &nExportStatus, &nProgress, ErrorInfo, &nErrorCode);
		printf("Export Status: %d, Progress: %d, ErrorCode: %d\n", nExportStatus, nProgress, nErrorCode);

		if (nErrorCode != PDC_SUCCEEDED) {
			printf("PDC_GetCihxSaveStatusA Error: %d\n", nErrorCode);
			break;
		}

		attempts++;
		if (attempts >= max_attempts) {
			printf("Timeout: Export process did not complete in time.\n");
			break;
		}

		Sleep(50);
	} while (nExportStatus != PDC_EXPORT_STATUS_COMPLETE);

	printf("TEST CIHX 4\n");
	PDC_ExitCihxSave(handle, &nErrorCode);
}
*/

// End processing
static BOOL Finalize()
{
	unsigned long nRet = 0;
	unsigned long nErrorCode = PDC_SUCCEEDED;

	if (g_bOpen)
	{
		_tprintf(_T("PDC_CloseDevice...\n"));
		nRet = PDC_CloseDevice(
			g_nDeviceNo,
			&nErrorCode);
		if (nRet == PDC_SUCCEEDED)
		{
			_tprintf(_T("\tOK (Device No=%u)\n"), g_nDeviceNo);
			return TRUE;
		}
		else
		{
			_tprintf(_T("\tNG (Error Code=%u Device No=%u)\n"), nErrorCode, g_nDeviceNo);
			return FALSE;
		}
	}
	else
	{
		return TRUE;
	}
}

// Split string
static void SpliString(LPTSTR lpszString, LPCTSTR lpszDelimiter, LPTSTR lpszStringList[], int& count, int& countTotal)
{
	LPTSTR lpszToken = NULL;
	LPTSTR lpszNextToken = NULL;
	count = 0;
	countTotal = 0;

	lpszToken = _tcstok_s(lpszString, lpszDelimiter, &lpszNextToken);
	while (lpszToken != NULL)
	{
		if (countTotal < MAX_COUNT_IP_ELEMENT)
		{
			lpszStringList[count++] = lpszToken;
		}
		lpszToken = _tcstok_s(NULL, lpszDelimiter, &lpszNextToken);
		countTotal++;
	}
}

// Check Number
static BOOL IsNumber(LPCTSTR lpszString)
{
	for (size_t i = 0; i < _tcslen(lpszString); i++)
	{
		if (!_istdigit(lpszString[i]))
		{
			return FALSE;
		}
	}
	return TRUE;
}

// Device Search & Device Open
bool ConnectToCamera(const std::string& ipAddress, bool autoDetect) {
	unsigned long nRet = 0;
	unsigned long nErrorCode = PDC_SUCCEEDED;
	std::vector<unsigned long> pIPList(PDC_MAX_DEVICE, 0);
	PDC_DETECT_NUM_INFO detectNumInfo = {};
	unsigned long nDeviceNo = 0;
	PPDC_DETECT_INFO pDetectInfo = nullptr;
	unsigned long nExistChildCount = 0;
	std::vector<unsigned long> pExistChildsNo(PDC_MAX_LIST_NUMBER, 0);
	unsigned long nChildNo = 0;

	if (autoDetect) {
		pIPList[0] = 0xC0A80000;  // 192.168.0.x
		nRet = PDC_DetectDevice(PDC_INTTYPE_G_ETHER, pIPList.data(), PDC_MAX_DEVICE, PDC_DETECT_AUTO, &detectNumInfo, &nErrorCode);
		pIPList[0] = 0xC0A80100;
		nRet = PDC_DetectDevice(PDC_INTTYPE_G_ETHER, pIPList.data(), PDC_MAX_DEVICE, PDC_DETECT_AUTO, &detectNumInfo, &nErrorCode);
	}
	else {
		pIPList[0] = ConvertIpStringToInt(ipAddress);  // Helper function to convert IP to integer

		std::cout << ipAddress << std::endl;

		nRet = PDC_DetectDevice(PDC_INTTYPE_G_ETHER, pIPList.data(), 1, PDC_DETECT_NORMAL, &detectNumInfo, &nErrorCode);
	}

	if (nRet != PDC_SUCCEEDED || detectNumInfo.m_nDeviceNum == 0) {
		printf("Device detection failed. Error Code: %u\n", nErrorCode);
		return false;
	}

	pDetectInfo = &detectNumInfo.m_DetectInfo[0];
	nRet = PDC_OpenDevice(pDetectInfo, &nDeviceNo, &nErrorCode);
	if (nRet != PDC_SUCCEEDED) {
		printf("Device open failed. Error Code: %u\n", nErrorCode);
		return false;
	}

	g_bOpen = true;
	g_nDeviceNo = nDeviceNo;

	nRet = PDC_GetExistChildDeviceList(nDeviceNo, &nExistChildCount, pExistChildsNo.data(), &nErrorCode);
	if (nRet != PDC_SUCCEEDED || nExistChildCount == 0) {
		printf("No child devices found. Error Code: %u\n", nErrorCode);
		return false;
	}

	g_nChildNo = pExistChildsNo[0];
	return true;
}

// Helper function to convert IP to integer
unsigned long ConvertIpStringToInt(const std::string& ip) {
	unsigned long result = 0;
	std::stringstream ss(ip); // Ensure <sstream> is included
	std::string segment;
	int shift = 24;
	while (std::getline(ss, segment, '.') && shift >= 0) {
		result += (std::stoi(segment) & 0xFF) << shift;
		shift -= 8;
	}
	return result;
}

// Function to get the next available index for a file in a directory
int GetNextAvailableIndex(const std::string& directory, const std::string& prefix, const std::string& extension, int padding) {
	int index = 1;
	while (true) {
		std::stringstream filename;
		filename << prefix << std::setw(padding) << std::setfill('0') << index << extension;
		fs::path fullPath = fs::path(directory) / filename.str();
		if (!fs::exists(fullPath)) {
			break;
		}
		index++;
	}
	return index;
}

json LoadLog(const std::string& logPath) {
	std::ifstream file(logPath);
	if (!file.is_open()) return json{ {"status", "ready"}, {"n_recorded", 0}, {"cases", json::object()} };
	json j;
	file >> j;
	return j;
}

void SaveLog(const std::string& logPath, const json& j) {
	std::ofstream file(logPath);
	file << std::setw(4) << j << std::endl;
}

void UpdateLogStatus(const std::string& logPath, const std::string& caseName, const std::string& newStatus) {
	auto log = LoadLog(logPath);
	if (log.contains("cases") && log["cases"].contains(caseName)) {
		log["cases"][caseName]["status"] = newStatus;
	}
	log["status"] = newStatus;  // optional: global status
	SaveLog(logPath, log);
}
