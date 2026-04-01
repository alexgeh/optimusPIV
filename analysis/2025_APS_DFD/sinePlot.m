%% Sinusoidal function plot

t = linspace(0,1,201);

figure,
plot(t, sin(2*pi*t-0.125*pi), 'LineWidth', 1.5)%, 'Color', 'black')
xlabelg('$$t \, / \, T$$'); ylabelg('$$\varphi \, / \, \hat{\varphi}$$');
ylim(1.1*[-1 1]);
xticks(0:0.25:1); yticks(-1:0.5:1);
box on;
ax = gca;
ax.FontSize = 14; 
