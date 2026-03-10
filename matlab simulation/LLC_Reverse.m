%% design_llc.m
% 半桥LLC谐振变换器参数自动设计
% 输入：Vin(标称或范围)、Vout、fr
% 输出：n, Lr, Cr, Lm，并检查简化ZVS条件
%
% 说明：
% 1) 采用 FHA（基波近似）进行初值设计
% 2) 采用简化 ZVS 约束：励磁电流需足够在死区内充放 MOSFET 的 Coss
% 3) 适用于 PFC + LLC 的后级半桥 LLC 初始参数选型
%
% 作者可直接修改下面"用户输入区"

clc; clear; close all;

%% ===================== 用户输入区 =====================
% Vin 可以填：
% 1) 标称值，例如 Vin = 390;
% 2) 范围，例如 Vin = [380 390 420];  % [Vin_min Vin_nom Vin_max]
Vin  = [380 390 420];     % LLC输入母线电压(V)
Vout = 12;                % 输出电压(V)
fr   = 100e3;             % 谐振频率(Hz)

% 下面这些是设计时必须补充的工程参数
opt.Pout        = 300;        % 输出功率(W)
opt.eta         = 0.94;       % 预估效率
opt.Vf          = 0.0;        % 次级整流等效压降(V), 同步整流可近似取0
opt.deadtime    = 200e-9;     % 死区时间(s)
opt.Coss        = 150e-12;    % 单个MOSFET输出电容(F)
opt.fsMinRatio  = 0.70;       % 最低工作频率 / fr
opt.fsMaxRatio  = 1.80;       % 最高工作频率 / fr
opt.zvsMargin   = 1.20;       % ZVS安全系数
opt.targetLn    = 6.0;        % 期望 Lm/Lr
opt.targetQe    = 0.40;       % 期望品质因数Qe
opt.LnCandidates = 4.0:0.25:9.0;
opt.QeCandidates = 0.25:0.01:0.60;

%% ===================== 计算 =====================
result = llc_design_auto(Vin, Vout, fr, opt);

%% ===================== 输出结果 =====================
fprintf('\n========== LLC 设计结果 ==========\n');
fprintf('输入电压范围 Vin = [%.1f, %.1f, %.1f] V\n', ...
    result.Vin_min, result.Vin_nom, result.Vin_max);
fprintf('输出电压 Vout = %.3f V\n', result.Vout);
fprintf('输出功率 Pout = %.1f W\n', result.Pout);
fprintf('谐振频率 fr = %.1f kHz\n', result.fr/1e3);

fprintf('\n--- 设计得到的谐振腔参数 ---\n');
fprintf('变压器变比 n = Np/Ns = %.4f\n', result.n);
fprintf('负载等效电阻 Rload = %.4f ohm\n', result.Rload);
fprintf('原边交流等效负载 Re = %.4f ohm\n', result.Re);
fprintf('Qe = %.3f\n', result.Qe);
fprintf('Ln = Lm/Lr = %.3f\n', result.Ln);
fprintf('Lr = %.3f uH\n', result.Lr * 1e6);
fprintf('Cr = %.3f nF\n', result.Cr * 1e9);
fprintf('Lm = %.3f uH\n', result.Lm * 1e6);

fprintf('\n--- 增益与频率检查 ---\n');
fprintf('所需最大增益 Gmax_req = %.3f\n', result.Gmax_req);
fprintf('所需最小增益 Gmin_req = %.3f\n', result.Gmin_req);
fprintf('在 fs_min = %.1f kHz 时 FHA增益 = %.3f\n', ...
    result.fs_min/1e3, result.G_at_fs_min);
fprintf('在 fs_max = %.1f kHz 时 FHA增益 = %.3f\n', ...
    result.fs_max/1e3, result.G_at_fs_max);

fprintf('\n--- 软开关(ZVS)检查 ---\n');
fprintf('所需最小换流电流 Ireq = %.3f A\n', result.Ireq_zvs);
fprintf('可提供励磁峰值电流 Imag_pk = %.3f A\n', result.Imag_pk);
fprintf('ZVS判定 = %d (1表示满足，0表示不满足)\n', result.zvs_ok);

if ~result.feasible
    fprintf('\n警告：在当前约束下未找到完全满足增益+ZVS条件的最优解，输出的是最接近的候选解。\n');
end

%% ===================== 画图 =====================
fn = linspace(0.5, 2.0, 1000);
Mg = arrayfun(@(x) llc_gain_fha(x, result.Ln, result.Qe), fn);

figure('Color','w');
plot(fn, Mg, 'LineWidth', 1.8); grid on; hold on;
yline(result.Gmax_req, '--r', 'G_{max req}');
yline(result.Gmin_req, '--b', 'G_{min req}');
xline(result.fs_min/result.fr, '--k', 'f_{s,min}/f_r');
xline(result.fs_max/result.fr, '--m', 'f_{s,max}/f_r');
xlabel('f_s / f_r');
ylabel('FHA增益 M_g');
title('LLC FHA增益曲线');
legend('M_g(f_n)', 'G_{max req}', 'G_{min req}', ...
       'f_{s,min}/f_r', 'f_{s,max}/f_r', 'Location', 'best');

%% ===================== 主函数 =====================
function result = llc_design_auto(Vin, Vout, fr, opt)

    % ---------- 解析输入电压 ----------
    if isscalar(Vin)
        Vin_min = Vin;
        Vin_nom = Vin;
        Vin_max = Vin;
    elseif numel(Vin) == 2
        Vin_min = min(Vin);
        Vin_max = max(Vin);
        Vin_nom = mean(Vin);
    else
        Vin = Vin(:).';
        Vin_min = Vin(1);
        Vin_nom = Vin(2);
        Vin_max = Vin(3);
    end

    % ---------- 基本量 ----------
    Pout   = opt.Pout;
    Vf     = opt.Vf;
    fs_min = opt.fsMinRatio * fr;
    fs_max = opt.fsMaxRatio * fr;

    % 半桥LLC常用初值：额定点在谐振点附近工作，令增益约1
    % n = Np/Ns
    n = Vin_nom / (2 * (Vout + Vf));

    % 直流负载
    Rload = Vout^2 / Pout;

    % FHA等效交流负载（半桥LLC常用近似）
    Re = (8 / pi^2) * n^2 * Rload;

    % 该变比下所需增益范围
    Gmax_req = 2 * n * (Vout + Vf) / Vin_min;
    Gmin_req = 2 * n * (Vout + Vf) / Vin_max;

    % ---------- 搜索最优 Ln 与 Qe ----------
    best.cost = inf;
    best.feasible = false;

    for Ln = opt.LnCandidates
        for Qe = opt.QeCandidates

            % 由 Qe 和 fr 反算谐振腔
            Zr = Qe * Re;
            Lr = Zr / (2 * pi * fr);
            Cr = 1 / (2 * pi * fr * Zr);
            Lm = Ln * Lr;

            % FHA增益检查
            G_at_fs_min = llc_gain_fha(fs_min / fr, Ln, Qe);
            G_at_fs_max = llc_gain_fha(fs_max / fr, Ln, Qe);

            gain_ok = (G_at_fs_min >= Gmax_req) && (G_at_fs_max <= Gmin_req);

            % --------- 简化ZVS检查 ---------
            % 死区内需要足够电流给上下管Coss换流
            % 保守估算：Ireq = zvsMargin * 2*Coss*Vin_max/deadtime
            Ireq = opt.zvsMargin * 2 * opt.Coss * Vin_max / opt.deadtime;

            % 近似认为最差ZVS出现在最高开关频率附近
            % 半桥励磁峰值电流粗估：Imag_pk = Vin_max / (4*Lm*fs_max)
            Imag_pk = Vin_max / (4 * Lm * fs_max);

            zvs_ok = Imag_pk >= Ireq;

            feasible = gain_ok && zvs_ok;

            % 代价函数：尽量靠近目标 Ln、Qe，同时偏向满足约束
            cost = abs(Ln - opt.targetLn) + 2 * abs(Qe - opt.targetQe);

            if ~gain_ok
                cost = cost + 100;
            end
            if ~zvs_ok
                cost = cost + 100;
            end

            if cost < best.cost
                best.cost        = cost;
                best.feasible    = feasible;
                best.Ln          = Ln;
                best.Qe          = Qe;
                best.Lr          = Lr;
                best.Cr          = Cr;
                best.Lm          = Lm;
                best.G_at_fs_min = G_at_fs_min;
                best.G_at_fs_max = G_at_fs_max;
                best.Ireq        = Ireq;
                best.Imag_pk     = Imag_pk;
                best.zvs_ok      = zvs_ok;
                best.gain_ok     = gain_ok;
            end
        end
    end

    % ---------- 输出 ----------
    result.Vin_min = Vin_min;
    result.Vin_nom = Vin_nom;
    result.Vin_max = Vin_max;
    result.Vout    = Vout;
    result.Pout    = Pout;
    result.fr      = fr;
    result.fs_min  = fs_min;
    result.fs_max  = fs_max;

    result.n       = n;
    result.Rload   = Rload;
    result.Re      = Re;
    result.Gmax_req = Gmax_req;
    result.Gmin_req = Gmin_req;

    result.Ln      = best.Ln;
    result.Qe      = best.Qe;
    result.Lr      = best.Lr;
    result.Cr      = best.Cr;
    result.Lm      = best.Lm;

    result.G_at_fs_min = best.G_at_fs_min;
    result.G_at_fs_max = best.G_at_fs_max;

    result.Ireq_zvs = best.Ireq;
    result.Imag_pk  = best.Imag_pk;
    result.zvs_ok   = best.zvs_ok;
    result.gain_ok  = best.gain_ok;
    result.feasible = best.feasible;
end

%% ===================== LLC FHA增益函数 =====================
function M = llc_gain_fha(fn, Ln, Qe)
    % fn = fs/fr
    % Ln = Lm/Lr
    % Qe = sqrt(Lr/Cr)/Re
    %
    % 常用FHA归一化增益表达式（半桥LLC初值设计）
    %
    %                 Ln * fn^2
    % M(fn) = ----------------------------------
    %         sqrt( ((Ln+1)fn^2 - 1)^2
    %               + [Ln*Qe*fn*(fn^2-1)]^2 )

    num = Ln * fn^2;
    den = sqrt( ((Ln + 1) * fn^2 - 1)^2 + (Ln * Qe * fn * (fn^2 - 1))^2 );
    M = num / den;
end