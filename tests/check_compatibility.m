% check_compatibility.m
% 扫描仓库中常见的 MATLAB 兼容性问题（当前检查：zeros(...,'complex')）
% 用法：在项目根目录下运行 `tests/check_compatibility` 或 `run('tests/check_compatibility.m')`

fprintf('Scanning for incompatible zeros(...,''complex'') usages...\n');

pattern = 'zeros\s*\([^)]*''complex''[^)]*\)';

files = dir('**/*.m');
found = {};

for fi = 1:numel(files)
    fp = fullfile(files(fi).folder, files(fi).name);
    try
        txt = fileread(fp);
    catch
        fprintf('  (skip) cannot read %s\n', fp);
        continue;
    end

    % 按行检查以便显示行号
    lines = regexp(txt, '\n', 'split');
    for li = 1:numel(lines)
        if ~isempty(regexpi(lines{li}, pattern))
            found{end+1,1} = fp; %#ok<SAGROW>
            found{end,2} = li; %#ok<SAGROW>
        end
    end
end

if isempty(found)
    fprintf('No incompatible usages found.\n');
else
    fprintf('Found %d incompatible usage(s):\n', size(found,1));
    for k = 1:size(found,1)
        fprintf('  %s : line %d\n', found{k,1}, found{k,2});
    end
    fprintf('\nRecommendation: replace occurrences like:\n');
    fprintf("  zeros(n,m,'complex')  ->  complex(zeros(n,m))\n");
end
