% main QPsw script:
% - calls demultiplex
% - calls calibration calculation
% - calls calibration interpolation
% - calls data recalculation
% Result are waveforms without digitizer errors.

function [y, yc, res] = qpsw_process(sigconfig, y, S, M, Uref1period, Spjvs, alg, dbg);
    % check input data %<<<1
    if nargin ~= 8
        error('qpsw_process: bad number of input arguments!')
    end
    check_gen_dbg(dbg);
    check_sigconfig(sigconfig);
    % ensure the directory for plots exists
    if dbg.v
        if dbg.saveplotsplt || dbg.saveplotspng
            if ~exist(dbg.plotpath, 'dir')
                mkdir(dbg.plotpath);
            end
        end
    end

    % split multiplexed data into sections %<<<1
    yc = qpsw_demultiplex_split(y, S, M);
    % DEBUG plot sections %<<<2
    if dbg.v
        figure('visible',dbg.showplots)
        title('raw waveform sections after splitting')
        hold on
        % does not work for multichannel records!
        cells = [1:4];
        legc = {};
        for c = cells
            if size(yc, 2) >= c
                plot(yc{c});
                legc(end+1) = {num2str(c)};
            end
        end
        plot([sigconfig.MRs sigconfig.MRs], ylim,'-k')
        legc(end+1) = 'MRs-points removed before this line';
        plot([numel(yc{1})-sigconfig.MRe numel(yc{1})-sigconfig.MRe], ylim,'-k')
        legc(end+1) = 'MRe-points removed after this line';
        legend(legc);
        hold off
        fn = fullfile(dbg.plotpath, 'sections1');
        if dbg.saveplotsplt printplt(fn) end
        if dbg.saveplotspng print([fn '.png'], '-dpng') end

        figure('visible',dbg.showplots)
        title('raw waveform sections after splitting')
        hold on
        % does not work for multichannel records!
        cells = [10:10:40];
        legc = {};
        for c = cells
            if size(yc, 2) >= c
                plot(yc{c});
                legc(end+1) = {num2str(c)};
            end
        end
        plot([sigconfig.MRs sigconfig.MRs], ylim,'-k')
        legc(end+1) = 'MRs-points removed before this line';
        plot([numel(yc{1})-sigconfig.MRe numel(yc{1})-sigconfig.MRe], ylim,'-k')
        legc(end+1) = 'MRe-points removed after this line';
        legend(legc);
        hold off
        fn = fullfile(dbg.plotpath, 'sections2');
        if dbg.saveplotsplt printplt(fn) end
        if dbg.saveplotspng print([fn '.png'], '-dpng') end
    end % if DEBUG

    % get calibration data from particular sections %<<<1
    ycal = calibrate_sections(yc, M, S, Uref1period, Spjvs, sigconfig, dbg);

    % recalibrate measurements %<<<1
    for i = 1:rows(yc)
            for j = 1:columns(yc)
                    % recalculate values according the gain
                    if M(i, j) > 0
                            % only non-quantum data
                            % XXX 2DO should be general polynomial, in case someone would like to calculate polynomials of higher order
                            yc{i, j} = ycal(i, j).coefs.v(1) + yc{i, j}.*ycal(i, j).coefs.v(2);
                    end % if M(i, j) > 0
            end % for j = 1:columns(yc)
    end % for i = 1:rows(yc)

    % finish demultiplexing - sew %<<<1
    % yc is rewritten
    [y, yc, My] = qpsw_demultiplex_sew(yc, M);

    % debug plot demultiplexed signal %<<<2
    if dbg.v
        colors = 'rgbkcyrgbkcyrgbkcyrgbkcy';
        legc = [];
        % make time axis:
        t = [0:size(y,2) - 1]./sigconfig.fs;
        figure('visible',dbg.showplots)
        hold on
        % estimate amplitudes, so waveforms can be offseted:
        plotoffset = max(max(y))*2.1;
        % plot signal
        for i = 1:rows(y)
                plot(t, y(i, :) - plotoffset.*(i-1), [colors(i) '-'])
                legc{end+1} = (['Signal ' num2str(i)]);
        end % for i
        % plot switch events
        minmax = ylim;
        minmax(1) = minmax(1) - abs(minmax(2) - minmax(1)).*0.1;
        minmax(2) = minmax(2) + abs(minmax(2) - minmax(1)).*0.1;
        for i = 1:length(S)
            if S(i) <= size(t,2)
                plot([t(S(i)) t(S(i))], minmax)
            end
        end % for i
        legend(legc)
        title('Demultiplexed signals, offseted')
        hold off
        fn = fullfile(dbg.plotpath, 'demultiplexed');
        if dbg.saveplotsplt printplt(fn) end
        if dbg.saveplotspng print([fn '.png'], '-dpng') end
    end % if dbg.v

    % calculate amplitude and phase of sections %<<<1
    % calls QWTB algorithm for every nonquantum section
    res = struct();
    for i = 1:rows(yc)
            if My(i) > 0 % only non-quantum data
                for j = 1:columns(yc)
                        if ~all(isnan(yc{i,j}))
                            % calculate data
                            DI.y.v = yc{i, j};
                            DI.fs.v = sigconfig.fs;
                            res(i,j) = qwtb(alg, DI);
                        endif
                end % for j = 1:columns(yc)
            end % if My > 0 % only non-quantum data
    end % for i = 1:rows(yc)

    % DEBUG plot amplitudes and offsets vs time %<<<2
    if dbg.v
        for i = 1:rows(res)
                for j = 1:columns(res)
                        % for cycle because matlab has issues with indexing concatenation ([x].y)
                        if isempty(res(i,j).A)
                            offsets(i,j) = nan;
                            amps(i,j) = nan;
                        else
                            if isfield(res(i,j), 'O')
                                offsets(i,j) = res(i,j).O.v;
                            else
                                offsets(i,j) = nan;
                            end
                            if isfield(res(i,j), 'A')
                                amps(i,j) = res(i,j).A.v;
                            else
                                offsets(i,j) = nan;
                            end
                        end
                end % for j = 1:columns(res)
        end % for i = 1:rows(res)
        figure('visible',dbg.showplots)
        hold on
            plot(amps', '-x')
            title('calculated amplitudes, digitizer gain corrected')
            xlabel('sampled waveform section (index)')
            ylabel('amplitude (V)')
            % legend('amplitude');
        hold off
        fn = fullfile(dbg.plotpath, 'amplitudes');
        if dbg.saveplotsplt printplt(fn) end
        if dbg.saveplotspng print([fn '.png'], '-dpng') end

        figure('visible',dbg.showplots)
        hold on
            plot(1e6.*offsets', '-x')
            title('calculated amplitude offsets, digitizer offset corrected')
            xlabel('sampled waveform section')
            ylabel('offset (uV)')
            % legend('offset');
        hold off
        fn = fullfile(dbg.plotpath, 'offsets');
        if dbg.saveplotsplt printplt(fn) end
        if dbg.saveplotspng print([fn '.png'], '-dpng') end
    end % if DEBUG
end

% tests %<<<1
% this function is tested by using qpsw_test.m

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=octave textwidth=80 tabstop=4 shiftwidth=4
