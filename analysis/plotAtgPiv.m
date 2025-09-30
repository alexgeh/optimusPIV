%%

clear
darkMode = false;
variousColorMaps();

[u, v, cr, x, y] = readVC7Folder("R:\ENG_Breuer_Shared\group\ATG\ATG_PIV\Wind_Turbine_20250609\ATG_250822_003\StereoPIV_MPd(2x32x32_75%ov)_GPU");
x = x(:,:,1);
y = y(:,:,1);

Uinf_est = mean(u,"all");


%%
limits = [0.5, 1.5];
nLevel = 20;

for mpti = 1:5000
    toplot = u(:,:,mpti) / Uinf_est;

    [C,h] = contourf(x, y, toplot, [nanmin2(toplot),linspace(limits(1),limits(2),nLevel),nanmax2(toplot)]);
    set(h,'linestyle','none')
    % quiver(x(cropX, cropY), -y(cropX, cropY), mean(u(cropX, cropY, :),3), mean(v(cropX, cropY, :),3), "off")
    clim(limits)
    colormap(uColorMap)
    cb = colorbar();
    ylabel(cb, 'mean(v) / U_{\infty}','FontSize',16)
    
    pause(0.1)
%     waitforbuttonpress()
end
