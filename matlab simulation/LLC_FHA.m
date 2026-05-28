%% LLC Attainable Peak Gain (Mg_ap) vs Quality Factor (Qe)
clear; clc; close all;

%% 1) 参数设置
% 定义需要绘制的电感比 Ln 列表 (对应图例)
Ln_list = [1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 9.0];

% 定义 Qe 的扫描范围 (X轴)
Qe_sweep = linspace(0.15, 1.25, 300);

% 定义归一化频率 fn 的扫描范围 (用于寻找峰值，峰值通常在 fn < 1 区域)
fn_sweep = linspace(0.1, 1.0, 5000); 

% 预分配峰值增益矩阵
Mg_ap = zeros(length(Ln_list), length(Qe_sweep));

%% 2) 核心计算：遍历求取峰值增益
% 根据 FHA 增益公式，对每一个 Ln 和 Qe 组合，在 fn 范围内寻找最大值
for i = 1:length(Ln_list)
    Ln = Ln_list(i);
    for j = 1:length(Qe_sweep)
        Qe = Qe_sweep(j);
        
        % FHA 增益公式
        % Mg = 1 / sqrt( (1 + 1/Ln - 1/(Ln*fn^2))^2 + Qe^2*(fn - 1/fn)^2 )
        term1 = (1 + 1./Ln - 1./(Ln .* fn_sweep.^2)).^2;
        term2 = (Qe.^2) .* (fn_sweep - 1./fn_sweep).^2;
        Mg_curve = 1 ./ sqrt(term1 + term2);
        
        % 提取该条件下的最高点 (即 Attainable Peak Gain)
        Mg_ap(i, j) = max(Mg_curve);
    end
end

%% 3) 计算并提取 Ln=3.5 的插值曲线 (用于复刻原图的标注)
Ln_35 = 3.5;
Mg_ap_35 = zeros(1, length(Qe_sweep));
for j = 1:length(Qe_sweep)
    Qe = Qe_sweep(j);
    term1 = (1 + 1./Ln_35 - 1./(Ln_35 .* fn_sweep.^2)).^2;
    term2 = (Qe.^2) .* (fn_sweep - 1./fn_sweep).^2;
    Mg_ap_35(j) = max(1 ./ sqrt(term1 + term2));
end

%% 4) 绘图与格式化
figure('Color', 'w', 'Position', [150, 100, 700, 650]);
hold on; grid on;

% 定义线条颜色 (尽量接近原图风格)
colors = lines(length(Ln_list));
colors(1,:) = [0.2, 0.2, 0.5]; % Ln=1.5 深蓝
colors(2,:) = [0.7, 0.1, 0.5]; % Ln=2.0 紫色
colors(3,:) = [0.8, 0.5, 0.1]; % Ln=3.0 橙色

% 绘制主曲线
h_lines = zeros(1, length(Ln_list));
for i = 1:length(Ln_list)
    h_lines(i) = plot(Qe_sweep, Mg_ap(i,:), 'LineWidth', 2, 'Color', colors(i,:));
end

% 绘制 Ln=3.5 的参考曲线 (细实线)
plot(Qe_sweep, Mg_ap_35, 'k-', 'LineWidth', 1.0, 'Color', [0.4 0.4 0.4]);

%% 5) 添加原图中的关键参考点与虚线
% 点1: Ln=3.5, Qe=0.45
Qe_pt1 = 0.45;
Mg_pt1 = interp1(Qe_sweep, Mg_ap_35, Qe_pt1); % 应该在 1.56 左右
plot([Qe_pt1, Qe_pt1], [1.0, Mg_pt1], 'r--', 'LineWidth', 1.5);
plot([0.15, Qe_pt1], [Mg_pt1, Mg_pt1], 'r--', 'LineWidth', 1.5);
plot(Qe_pt1, Mg_pt1, 'ko', 'MarkerSize', 6, 'LineWidth', 1.5, 'MarkerFaceColor', 'w');

% 点2: Ln=5.0, Qe=0.5
Qe_pt2 = 0.50;
Mg_pt2 = interp1(Qe_sweep, Mg_ap(5,:), Qe_pt2); % 应该在 1.2 左右
plot([Qe_pt2, Qe_pt2], [1.0, Mg_pt2], 'r--', 'LineWidth', 1.5);
plot([0.15, Qe_pt2], [Mg_pt2, Mg_pt2], 'r--', 'LineWidth', 1.5);
plot(Qe_pt2, Mg_pt2, 'ko', 'MarkerSize', 6, 'LineWidth', 1.5, 'MarkerFaceColor', 'w');

%% 6) 添加文本标注
% 为各个 Ln 曲线添加文字指示 (调整坐标以匹配原图位置)
text(0.80, 1.65, '\leftarrow L_n = 1.5', 'FontSize', 11, 'FontWeight', 'bold');
text(0.35, 2.30, '\leftarrow L_n = 3.0', 'FontSize', 11, 'FontWeight', 'bold');

% 标注参考点数据
txt1 = {'L_n = 3.5 by', 'Interpolation', sprintf('M_{g\\_ap} = %.2f', Mg_pt1), sprintf('Q_e = %.2f', Qe_pt1)};
text(0.40, 1.70, txt1, 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

txt2 = {'L_n = 5', sprintf('M_{g\\_ap} = %.2f', Mg_pt2), sprintf('Q_e = %.2f', Qe_pt2)};
text(0.58, 1.25, txt2, 'FontSize', 10, 'FontWeight', 'bold');

%% 7) 坐标轴细节调整
set(gca, 'FontSize', 12, 'FontWeight', 'bold', 'LineWidth', 1.5, ...
         'XTick', 0.15:0.2:1.25, 'YTick', 1.0:0.2:3.0);
xlim([0.15, 1.25]);
ylim([1.0, 3.0]);

xlabel('Quality Factor, \bf{Q_e}', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Attainable Peak Gain, \bf{M_{g\_ap}}', 'FontSize', 14, 'FontWeight', 'bold');

% 添加图例
legend_strs = arrayfun(@(x) sprintf('L_n = %.1f', x), Ln_list, 'UniformOutput', false);
legend(h_lines, legend_strs, 'Location', 'northeast', 'FontSize', 11, 'EdgeColor', 'k');

hold off;