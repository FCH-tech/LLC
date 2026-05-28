%% LLC 归一化频率边界求解 (基于 FHA 与数值求根)
clear; clc;

%% 1. 输入设计参数
Lr = 70e-6;        % 谐振电感 Lr (H)
Cr = 36e-9;        % 谐振电容 Cr (F)
Lm = 245e-6;       % 励磁电感 Lm (H)
Qe = 0.52;         % 满载或过载条件下的品质因数 Qe
n  = 16;        % 变压器变比 Np/Ns

% 要解出频率，必须输入目标增益 (由输入输出规格计算得出)
Mg_max = 1.30;     % 最低输入电压对应的最大需求增益
Mg_min = 0.99;     % 最高输入电压对应的最小需求增益

%% 2. 衍生参数计算
Ln = Lm / Lr;                     % 电感比
fr = 1 / (2 * pi * sqrt(Lr * Cr)); % 串联谐振频率 (即 f0)

%% 3. 定义 FHA 电压增益数学模型
% 根据基波近似法(FHA)，定义增益 Mg 关于 fn 的匿名函数
% 公式: Mg(fn) = 1 / sqrt( [1 + (fn^2 - 1)/(Ln*fn^2)]^2 + [Qe*(fn^2 - 1)/fn]^2 )
Mg_func = @(fn) 1 ./ sqrt( (1 + (fn.^2 - 1)./(Ln .* fn.^2)).^2 + (Qe .* (fn.^2 - 1)./fn).^2 );

%% 4. 利用 fzero 函数进行非线性方程求解
fprintf('======================================================\n');
fprintf('                LLC 频率边界计算结果\n');
fprintf('======================================================\n');

% -------------------------------------------------------------
% 求解 fn_min (对应增益 Mg_max，通常工作在谐振点左侧，fn < 1)
% 使用 fzero 寻找方程 Mg_func(fn) - Mg_max = 0 的根，初始猜测值设为 0.7
% -------------------------------------------------------------
try
    % 寻找 Mg = Mg_max 时的 fn
    fn_min = fzero(@(fn) Mg_func(fn) - Mg_max, 0.7); 
    fs_min = fn_min * fr;
    fprintf('【最小频率边界】\n');
    fprintf('  目标最大增益 Mg_max = %.2f\n', Mg_max);
    fprintf('  求得 f_n_min      = %.3f\n', fn_min);
    fprintf('  实际 f_sw_min     = %.2f kHz\n\n', fs_min / 1e3);
catch
    disp('⚠️ 计算 fn_min 失败：可能是 Mg_max 设置过高，超出了当前 Qe 下的物理峰值增益！');
end

% -------------------------------------------------------------
% 求解 fn_max (对应增益 Mg_min，通常工作在谐振点右侧，fn > 1)
% 使用 fzero 寻找方程 Mg_func(fn) - Mg_min = 0 的根，初始猜测值设为 1.2
% -------------------------------------------------------------
try
    % 寻找 Mg = Mg_min 时的 fn
    fn_max = fzero(@(fn) Mg_func(fn) - Mg_min, 1.2); 
    fs_max = fn_max * fr;
    fprintf('【最大频率边界】\n');
    fprintf('  目标最小增益 Mg_min = %.2f\n', Mg_min);
    fprintf('  求得 f_n_max      = %.3f\n', fn_max);
    fprintf('  实际 f_sw_max     = %.2f kHz\n', fs_max / 1e3);
catch
    disp('⚠️ 计算 fn_max 失败：请检查 Mg_min 设置是否合理。');
end
fprintf('======================================================\n');