%% LLC resonant tank gain sweep for different Qe (FHA)
% 输出：M = |Vout1/Vin1|  (谐振腔基波电压增益)
% 说明：Qe = Zr / Rac,  Zr = sqrt(Lr/Cr)

clear; clc; close all;

%% 1) 设定谐振腔参数（示例）
Lr = 18e-6;      % 谐振电感 Lr (H)
Cr = 36e-9;     % 谐振电容 Cr (F)
Lm = 100e-6;      % 磁化电感 Lm (H)

k  = Lm/Lr;                          % 电感比
fr = 1/(2*pi*sqrt(Lr*Cr));           % 串联谐振频率 fo=fr
Zr = sqrt(Lr/Cr);                    % 特征阻抗

% 第二谐振频率（与 Lp=Lr+Lm 相关）
fp = 1/(2*pi*sqrt((Lr+Lm)*Cr));       % 并联谐振相关频率
fn_p = fp/fr;

fprintf('fr = %.1f kHz,  fp = %.1f kHz,  fp/fr = %.3f,  k=Lm/Lr=%.2f\n', ...
    fr/1e3, fp/1e3, fn_p, k);

%% 2) 扫频范围（归一化频率 fn = fs/fr）
fn = linspace(0.3, 3.0, 4000);   % 可按需要扩展到 0.2~5 等
fs = fn * fr;
w  = 2*pi*fs;

%% 3) 选择要对比的 Qe
Qe_list = [0.25 0.5 0.75 0.2759];   % 典型设计图常用范围，可自行改

M = zeros(numel(Qe_list), numel(fn));

%% 4) FHA 频域计算：阻抗法
% 等效电路：Vin1 -> (Lr 串 Cr) -> (Lm 并 Rac)
Zs = 1j*w*Lr + 1./(1j*w*Cr);     % Lr 串 Cr 的等效阻抗
Zm = 1j*w*Lm;                    % Lm 的阻抗

for ii = 1:numel(Qe_list)
    Qe  = Qe_list(ii);
    Rac = Zr / Qe;               % Qe = Zr/Rac -> Rac = Zr/Qe

    Zp = 1 ./ (1./Zm + 1./Rac);  % Lm || Rac
    G  = Zp ./ (Zs + Zp);        % Vout1/Vin1
    M(ii,:) = abs(G);
end

%% 5) 画图
figure('Color','w'); hold on; grid on;

for ii = 1:numel(Qe_list)
    plot(fn, M(ii,:), 'LineWidth', 1.8);
end

xline(1, '--', 'fn=1 (fs=fr)', 'LineWidth', 1.2);
xline(fn_p, ':', sprintf('fp/fr=%.3f', fn_p), 'LineWidth', 1.2);

xlabel('f_n = f_s / f_r');
ylabel('M = |V_{out,1} / V_{in,1}|');
title(sprintf('LLC谐振腔电压增益 vs 频率（不同Qe），k=Lm/Lr=%.2f', k));

leg = arrayfun(@(q) sprintf('Qe=%.2f', q), Qe_list, 'UniformOutput', false);
legend(leg, 'Location', 'best');

ylim([0, max(M(:))*1.1]);
xlim([fn(1), fn(end)]);

n  = 10;              % Np/Ns
Ro = 100000;             % 输出直流等效负载(Ohm)，示例
Rac_from_Ro = (8*n^2/pi^2) * Ro;   % 常见全波整流折算
Qe_from_Ro  = Zr / Rac_from_Ro;
fprintf('From Ro=%.3f ohm, n=%.2f -> Rac=%.3f ohm, Qe=%.4f\n', ...
    Ro, n, Rac_from_Ro, Qe_from_Ro);
