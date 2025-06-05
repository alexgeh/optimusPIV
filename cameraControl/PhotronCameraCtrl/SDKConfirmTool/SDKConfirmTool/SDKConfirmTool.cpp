// SDKConfirmTool.cpp
//
// This is a simple console application that demonstrates how to connect to a Photron camera and download high-speed video data.
// The application uses the Photron SDK to connect to a camera, set it to playback mode, and download video data in MRAW and CIHX formats.

//#define WINAPI __stdcall
#define PDC_API __cdecl

#include "stdafx.h"
#include "./../../PDCLIB/Include/PDCLIB.h"
//#include "PDCLIB.h"
#include<Windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include <vector>

#include <chrono>
#include <iomanip>
#include <sstream>
#include <filesystem>
#include <conio.h> // For _kbhit() and _getch()

#include <locale>
#include <codecvt>

namespace fs = std::filesystem;

#pragma comment(lib, "PDCLIB.lib")

// Const
#define MAX_LENGTH_IP_STRING	256	// max length xxx.xxx.xxx.xxx
#define MAX_COUNT_IP_ELEMENT	4	// max count 1.2.3.4

// Declaration
static BOOL Initialize();
bool ConnectToCamera(const std::string& ipAddress, bool autoDetect);
void RecordVideo(unsigned long nDeviceNo, unsigned long nChildNo, unsigned long nRate, unsigned long nFrames);
void SaveMRAW(unsigned long nDeviceNo, unsigned long nChildNo, const wchar_t* mrawPath, long nDownloadFrame);
void SaveCIHX(unsigned long nDeviceNo, unsigned long nChildNo, const char* cihxPath, long nDownloadFrame);
void DownloadHighSpeedVideo(unsigned long nDeviceNo, unsigned long nChildNo, const wchar_t* mrawPath, const char* cihxPath, long nTotalFrame);
unsigned long ConvertIpStringToInt(const std::string& ip);
static int SpliString(LPTSTR lpszString, LPCTSTR lpszDelimiter, LPTSTR lpszStringList[]);
static BOOL IsNumber(LPCTSTR lpszString);
static BOOL Finalize();

// Global variable
BOOL g_bOpen = FALSE;			// TRUE:Open FALSE:NotOpen
unsigned long g_nDeviceNo = 0;	// Device No
unsigned long g_nChildNo = 0;	// Child No

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
	UNREFERENCED_PARAMETER(argc);
	UNREFERENCED_PARAMETER(argv);

	_tsetlocale(LC_ALL, _T(".ACP"));

	std::string cameraIP = "192.168.1.10";  // Replace with the actual camera IP if known

	unsigned long nRate = 200; // Record rate in fps
	unsigned long nFrames = 400; // Number of frames to record

	const wchar_t* mrawPath = L"C:\\Users\\agehrke\\Downloads\\photronTestRec\\cpp_test_script\\test_1.mraw";
	const char* cihxPath = "C:\\Users\\agehrke\\Downloads\\photronTestRec\\cpp_test_script\\test_1.cihx";
	long totalFrames = nFrames; // Change as needed

	Initialize();

	// Connect to Camera
	std::cout << "\nConnecting to camera at " << cameraIP << "...\n";
	if (!ConnectToCamera(cameraIP, false)) {
		std::cerr << "Failed to connect to camera.\n";
		return -1;
	}
	std::cout << "Connection successful!\n";

	// Create a unique directory for this session
	std::string rootDir = "C:\\Users\\agehrke\\Downloads\\photronTestRec\\cpp_test_script\\";
	std::string sessionFolder = rootDir + "recording_" + GetTimestamp();
	fs::create_directory(sessionFolder);

	int videoIndex = 1;

	std::cout << "Press 'q' to stop recording...\n";

	while (true) {
		
		// Check for exit key
		if (_kbhit() && _getch() == 'q') {
			std::cout << "Exiting recording loop.\n";
			break;
		}

		// Generate filenames
		std::string timestamp = GetTimestamp();
		std::stringstream mrawName, cihxName;
		mrawName << sessionFolder << "\\video_" << videoIndex << "_" << timestamp << ".mraw";
		cihxName << sessionFolder << "\\video_" << videoIndex << "_" << timestamp << ".cihx";

		std::wstring mrawPath = StringToWString(mrawName.str());
		//std::wstring mrawPath = std::wstring(mrawName.str().begin(), mrawName.str().end());
		std::string cihxPath = cihxName.str();
		
		// Record and Save
		std::cout << "Recording video " << videoIndex << "...\n";
		RecordVideo(g_nDeviceNo, g_nChildNo, nRate, nFrames);
		DownloadHighSpeedVideo(g_nDeviceNo, g_nChildNo, mrawPath.c_str(), cihxPath.c_str(), nFrames);
		std::cout << "Video " << videoIndex << " saved successfully.\n";

		videoIndex++;
	}

	Finalize();

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

void RecordVideo(unsigned long nDeviceNo, unsigned long nChildNo, unsigned long nRate, unsigned long nFrames)
{
	unsigned long nRet;
	unsigned long nStatus;
	unsigned long nErrorCode;

	// Recording time in milliseconds - record extra frames as buffer, but only download requested number of frames
	unsigned long recordingTime = 1.1 * nFrames / nRate * 1000;

	nRet = PDC_SetTriggerMode(nDeviceNo, PDC_TRIGGER_RANDOM_RESET, nRate, nRate, nRate, &nErrorCode);
	if (nRet == PDC_FAILED) {
		printf("PDC_SetTriggerMode Error %d\n", nErrorCode);
		return;
	}

	nRet = PDC_SetRecordRate(nDeviceNo, nChildNo, nRate, &nErrorCode);
	if (nRet == PDC_FAILED) {
		printf("PDC_SetRecordRate Error %d\n", nErrorCode);
		return;
	}

	nRet = PDC_SetRecReady(nDeviceNo, &nErrorCode);
	if (nRet == PDC_FAILED) {
		printf("PDC_SetRecready Error %d\n", nErrorCode);
		return;
	}

	while (1) {
		nRet = PDC_GetStatus(nDeviceNo, &nStatus, &nErrorCode);
		if (nRet == PDC_FAILED) {
			printf("PDC_GetStatus Error %d\n", nErrorCode);
			break;
		}

		if (nStatus == PDC_STATUS_RECREADY || nStatus == PDC_STATUS_REC) {
			printf("Camera in recording mode - Ready to trigger.\n");
			break;
		}
	}

	while (1) {
		nRet = PDC_GetStatus(nDeviceNo, &nStatus, &nErrorCode);
		if (nRet == PDC_FAILED) {
			printf("PDC_GetStatus Error %d\n", nErrorCode);
			break;
		}

		if (nStatus != PDC_STATUS_RECREADY) {
			printf("Camera recording.\n");
			break;
		}
	}
	Sleep(recordingTime);

	// This turns off recording
	nRet = PDC_SetStatus(nDeviceNo, PDC_STATUS_LIVE, &nErrorCode);
	if (nRet == PDC_FAILED) {
		printf("PDC_SetStatus Error %d\n", nErrorCode);
	}

	nRet = PDC_SetStatus(nDeviceNo, PDC_STATUS_PLAYBACK, &nErrorCode);
	if (nRet == PDC_FAILED) {
		printf("PDC_SetStatus Error %d\n", nErrorCode);
	}
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

