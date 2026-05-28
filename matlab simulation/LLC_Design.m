%% LLC 谐振半桥转换器自动设计
clear; clc;

%% 1. 输入规格
spec.Vin_min = 375;     % 最小输入电压 (V)
spec.Vin_nom = 390;     % 标称输入电压 (V)
spec.Vin_max = 405;     % 最大输入电压 (V)
spec.Vo = 12;           % 额定输出电压 (V)
spec.Io = 25;           % 额定输出电流 (A)
spec.Po = spec.Vo * spec.Io;  % 额定输出功率 (W)
spec.eff = 0.92;        % 假设效率 (≥90%)
spec.VF = 0.7;          % 次级二极管正向压降 (V)
spec.Vloss = (spec.Po/spec.eff)*(1-spec.eff)/25;      % 功率损耗引起的等效压降 (V)
spec.reg = 0.01;        % 线路/负载调节率 ±1%
spec.overload = 1.10;   % 过载能力 110%
spec.f0_initial = 100e3; % 初始串联谐振频率 (Hz)
spec.Ln = 3.5;          % 电感比 Lm/Lr
spec.Qe = 0.45;         % 满载品质因数
spec.Cds = 870e-12;     % MOSFET 输出电容 (F)
spec.Vo_ripple_pp = 0.12; % 输出峰峰值纹波 (V)

fprintf('=== LLC 谐振转换器设计 ===\n');
fprintf('输入电压范围: %.0f - %.0f - %.0f V\n', spec.Vin_min, spec.Vin_nom, spec.Vin_max);
fprintf('输出电压: %.1f V\n', spec.Vo);
fprintf('输出电流: %.1f A\n', spec.Io);
fprintf('输出功率: %.1f W\n', spec.Po);
fprintf('目标效率: %.0f%%\n', spec.eff*100);
fprintf('过载能力: %.0f%%\n', spec.overload*100);
fprintf('\n');

%% 2. 计算变压器匝比 n
n = (spec.Vin_nom/2) / spec.Vo;
n = round(n);  % 取整
fprintf('1. 变压器匝比 n = %.2f → 取整为 %d\n', (spec.Vin_nom/2)/spec.Vo, n);

%% 3. 计算最小和最大增益 Mg_min, Mg_max
% 输出电压考虑调节率后的范围
Vo_min = spec.Vo * (1 - spec.reg);
Vo_max = spec.Vo * (1 + spec.reg);

% Mg_min (对应最大输入电压)
Mg_min = (n * (Vo_min + spec.VF)) / (spec.Vin_max/2);
% Mg_max (对应最小输入电压，考虑损耗，再乘过载系数)
Mg_max_base = (n * (Vo_max + spec.VF + spec.Vloss)) / (spec.Vin_min/2);
Mg_max = Mg_max_base * spec.overload;

fprintf('2. Mg_min = %.3f, Mg_max = %.3f (过载后)\n', Mg_min, Mg_max);

%% 4. 选择 Ln 和 Qe (已给定，验证是否满足)
% 根据给定 Ln 和 Qe，查图或内插得到最大可达增益 Mg_ap
% 这里简化为经验判断：若 Ln=3.5, Qe=0.45 通常可达增益 >1.3
% 更精确可用增益公式近似或查表，本设计直接信任文档
Mg_ap = 1.56;  % 来自文档说明
if Mg_ap < Mg_max
    warning('所选 Ln 和 Qe 可能无法满足增益要求，请重新选择');
else
    fprintf('3. Ln = %.1f, Qe = %.2f, 可达增益 Mg_ap ≈ %.2f > Mg_max ✓\n', spec.Ln, spec.Qe, Mg_ap);
end

%% 5. 计算等效负载电阻 Re (满载和过载)
Re_full = (8 * n^2 / pi^2) * (spec.Vo / spec.Io);
Re_over = (8 * n^2 / pi^2) * (spec.Vo / (spec.Io * spec.overload));
fprintf('4. 等效负载电阻: 满载 Re = %.1f Ω, 过载 Re = %.1f Ω\n', Re_full, Re_over);

%% 6. 设计谐振电路参数 (Cr, Lr, Lm)
% 使用初始 f0 和满载 Re、Qe 计算 Cr
Cr = 1 / (2*pi * spec.Qe * spec.f0_initial * Re_full);
% 选择标准电容组合 
Cr_std = 36e-9;  % 实际选用值
% 根据实际 Cr 重新计算 Lr0
Lr = round(1 / ((2*pi*spec.f0_initial)^2 * Cr_std) * 1e6) / 1e6;
Lm = spec.Ln * Lr;
fprintf('5. 谐振电路参数:\n');
fprintf('   理论 Cr = %.3f nF → 选用 %.1f nF (12nF×3 )\n', Cr*1e9, Cr_std*1e9);
fprintf('   谐振电感 Lr = %.1f μH\n', Lr*1e6);
fprintf('   励磁电感 Lm = %.1f μH\n', Lm*1e6);

%% 7. 验证实际谐振频率和品质因数
f0_actual = 1 / (2*pi*sqrt(Lr*Cr_std));
Ln_actual = Lm / Lr;
Qe_full_actual = sqrt(Lr/Cr_std) / Re_full;
Qe_over_actual = sqrt(Lr/Cr_std) / Re_over;
fprintf('6. 验证:\n');
fprintf('   实际串联谐振频率 f0 = %.1f kHz\n', f0_actual/1e3);
fprintf('   实际电感比 Ln = %.2f\n', Ln_actual);
fprintf('   满载品质因数 Qe = %.3f\n', Qe_full_actual);
fprintf('   过载品质因数 Qe = %.3f\n', Qe_over_actual);

%% 8. 频率范围确定 (通过增益曲线或给定 fn_min, fn_max)
% 文档中通过曲线得到 fn_min=0.65, fn_max=1.02 (对应过载情况)
fn_min = 0.657;
fn_max = 1.02;
fsw_min = fn_min * f0_actual;
fsw_max = fn_max * f0_actual;
fprintf('   最小开关频率 fsw_min = %.1f kHz (过载)\n', fsw_min/1e3);
fprintf('   最大开关频率 fsw_max = %.1f kHz (轻载)\n', fsw_max/1e3);

%% 9. 初级侧电流计算 (过载情况)
Ioe = (pi/(2*sqrt(2))) * (spec.Io * spec.overload) / n;
% 计算磁化电流 Im (在 fsw_min 处)
omega_min = 2*pi*fsw_min;
Im = 0.901 * (n * spec.Vo) / (omega_min * Lm);  % 0.901 为方波基波系数
Ir = sqrt(Im^2 + Ioe^2);
fprintf('\n7. 初级侧电流 (过载):\n');
fprintf('   等效负载电流 Ioe = %.2f A\n', Ioe);
fprintf('   磁化电流 Im = %.2f A\n', Im);
fprintf('   谐振电流 Ir = %.2f A\n', Ir);

%% 10. 次级侧电流计算
Ioe_s = n * Ioe;
Isw = (sqrt(2) * Ioe_s) / 2;   % 每个半波绕组 RMS
Isav = (sqrt(2) * Ioe_s) / pi; % 半波平均电流
fprintf('8. 次级侧电流:\n');
fprintf('   总次级 RMS 电流 Ioe_s = %.1f A\n', Ioe_s);
fprintf('   每个中心抽头绕组 RMS 电流 Isw = %.1f A\n', Isw);
fprintf('   半波平均电流 Isav = %.1f A\n', Isav);

%% 11. 变压器规格输出
fprintf('\n9. 变压器建议规格:\n');
fprintf('   匝数比 n = %d\n', n);
fprintf('   初级电压: %.0f VAC (按最大输入折算)\n', spec.Vin_max);
fprintf('   初级额定电流: %.1f A\n', Ir);
fprintf('   次级电压: %.0f VAC (空载)\n', n*spec.Vo);
fprintf('   次级绕组电流 (中心抽头): %.1f A\n', Isw);
fprintf('   工作频率范围: %.0f - %.0f kHz\n', fsw_min/1e3, fsw_max/1e3);
fprintf('   绝缘等级: IEC60950 加强绝缘\n');

%% 12. 谐振电感规格
VLr = 2*pi*fsw_min * Lr * Ir;  % 终端交流电压 (有效值)
fprintf('\n10. 谐振电感建议:\n');
fprintf('    电感量 Lr = %.1f μH\n', Lr*1e6);
fprintf('    额定电流: %.1f A\n', Ir);
fprintf('    终端交流电压: %.1f V (建议余量至 %.0f V)\n', VLr, ceil(VLr/10)*10);
fprintf('    频率范围: %.0f - %.0f kHz\n', fsw_min/1e3, fsw_max/1e3);

%% 13. 谐振电容电压应力
VCr_ac = Ir / (omega_min * Cr_std);
VCr_rms = sqrt((spec.Vin_max/2)^2 + VCr_ac^2);
VCr_peak = spec.Vin_max/2 + sqrt(2)*VCr_ac;
fprintf('\n11. 谐振电容建议:\n');
fprintf('    电容值 Cr = %.1f nF\n', Cr_std*1e9);
fprintf('    额定电流: %.1f A\n', Ir);
fprintf('    交流电压分量: %.1f V\n', VCr_ac);
fprintf('    RMS 总电压: %.1f V\n', VCr_rms);
fprintf('    峰值电压: %.1f V\n', VCr_peak);
fprintf('    推荐使用金属化聚丙烯薄膜电容，注意高频降额\n');

%% 14. MOSFET 选择
Vds_max = spec.Vin_max;
Ids_rms = Ir;
fprintf('\n12. 初级侧 MOSFET 建议:\n');
fprintf('    漏源电压额定值: %.0f V (建议 500 V)\n', Vds_max);
fprintf('    导通电流 RMS: %.2f A\n', Ids_rms);
fprintf('    要求低 Rds(on) 和低 Cds 以实现 ZVS\n');

%% 15. ZVS 条件验证
% 最小磁化电流 (在最高开关频率处)
fsw_max_abs = fsw_max;
Im_min = 0.901 * (n * spec.Vo) / (2*pi*fsw_max_abs * Lm);
% 存储能量
E_L = 0.5 * (Lm + Lr) * (sqrt(2)*Im_min)^2;
Ceq = spec.Cds;  % 假设 Ceq = Cds
E_C = 0.5 * (2*Ceq) * spec.Vin_max^2;
if E_L >= E_C
    zvs_energy_ok = true;
else
    zvs_energy_ok = false;
end
% 所需死区时间 (基于公式 32b)
t_dead_min = 16 * Ceq * fsw_max_abs * Lm;
% 原理：换算成纳秒(ns) -> 除以100 -> 向上取整 -> 乘回100 -> 换算回秒(s)
t_dead_recommend = ceil(t_dead_min * 1e9 / 100) * 100 * 1e-9;
fprintf('\n13. ZVS 设计验证:\n');
fprintf('    最小磁化电流 (fsw_max=%.1f kHz): Im_min = %.2f A\n', fsw_max_abs/1e3, Im_min);
fprintf('    电感存储能量: %.2f μJ\n', E_L*1e6);
fprintf('    电容存储能量: %.2f μJ\n', E_C*1e6);
if zvs_energy_ok
    fprintf('    能量条件满足 (E_L ≥ E_C) ✓\n');
else
    fprintf('    能量条件不满足，需增大 Lm 或提高最小频率 ✗\n');
end
fprintf('    所需最小死区时间: %.1f ns (推荐 %.0f ns)\n', t_dead_min*1e9, t_dead_recommend*1e9);

%% 16. 整流二极管选择
Vdiode = (spec.Vin_max/2)/n * 2;
Idiode_avg = Isav;
fprintf('\n14. 输出整流二极管建议:\n');
fprintf('    反向重复峰值电压: %.1f V (建议 %.0f V)\n', Vdiode, ceil(Vdiode/5)*5);
fprintf('    平均正向电流: %.1f A\n', Idiode_avg);
fprintf('    推荐使用肖特基二极管\n');

%% 17. 输出滤波电容
Irect_peak = (pi/4) * spec.Io * 2;  % 峰值电流 = (π/4)*Io*2
Ico_rms = sqrt( (pi/(2*sqrt(2))*spec.Io)^2 - spec.Io^2 );
ESR_max = spec.Vo_ripple_pp / Irect_peak;
fprintf('\n15. 输出滤波电容建议:\n');
fprintf('    纹波电流有效值: %.1f A (100 kHz)\n', Ico_rms);
fprintf('    最大 ESR: %.2f mΩ\n', ESR_max*1e3);
fprintf('    额定电压: ≥16 V\n');
fprintf('    推荐采用多个铝固态电容并联以满足纹波电流和 ESR 要求\n');

fprintf('\n=== 设计完成 ===\n');

%% 可选：绘制增益曲线 (基于 FHA 模型)
% 使用实际 Ln, Qe 绘制归一化增益曲线
figure;
fn = linspace(0.4, 1.5, 500);
Mg_full = 1 ./ sqrt( (1 + Ln_actual - 1./fn.^2).^2 + (Qe_full_actual^2 * (fn - 1./fn).^2) );
Mg_over = 1 ./ sqrt( (1 + Ln_actual - 1./fn.^2).^2 + (Qe_over_actual^2 * (fn - 1./fn).^2) );
plot(fn, Mg_full, 'b-', 'LineWidth', 1.5); hold on;
plot(fn, Mg_over, 'r--', 'LineWidth', 1.5);
xlabel('归一化频率 f_n = f_{sw}/f_0');
ylabel('增益 M_g');
legend(['Q_e = ' num2str(Qe_full_actual)], ['Q_e = ' num2str(Qe_over_actual)]);
title('LLC 谐振变换器增益曲线');
grid on;
xline(fn_min, 'k:', 'f_{n,min}');
xline(fn_max, 'k:', 'f_{n,max}');
yline(Mg_min, 'g--', 'M_{g,min}');
yline(Mg_max, 'm--', 'M_{g,max}');
hold off;