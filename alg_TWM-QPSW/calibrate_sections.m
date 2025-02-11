% Determines digitizer calibration values for all waveform sections.
% First obtains calibration values from PJVS sections, than copies values to sections with DUT signal.
%
% Developed in the scope of the EMPIR QPower.
% MIT license
%
% Inputs:
% yc - waveform sections in cell
% M - multiplexer matrix
% S - indexes of samples of new waveform sections start
% Uref1period - reference values of PJVS voltages for one PJVS period
% sigconfig - configuration data
%
% Outputs:
% cal - matrix with calibration data for every section

function ycal = calibrate_sections(yc, M, S, Uref1period, Spjvs, sigconfig, dbg)
    % XXX remove S input
    % initialize %<<<1
    % XXX check inputs

    % get calibration data for every quantum waveform section %<<<1
    empty_ycal.coefs = [];
    empty_ycal.exponents = [];
    empty_ycal.func = [];
    empty_ycal.model = [];
    empty_ycal.yhat = [];
    find_PR_done = 0; % flag, sets to one if PRs and PRe was automatically found, so it is not done again in next section
    for i = 1:rows(yc)
            for j = 1:columns(yc)
                    % check if quantum measurement:
                    if M(i, j) < 0
                            % do calibration
                            if isempty(Spjvs)
                                % Get length of PJVS segments in samples (samples between two different PJVS steps):
                                segmentlen = sigconfig.fs./sigconfig.fseg;
                                % Find out indexes of PJVS segments automatically:
                                dbg.section = [i, j];
                                tmpSpjvs = pjvs_ident_segments(yc{i,j}, sigconfig.MRs, sigconfig.MRe, segmentlen, dbg);
                            else %<<<4
                                error('deprecated?')
                                % This part used indexes of all PJVS segments
                                % through whole measurement and cuts it down
                                % into needed part. However in probably no
                                % measurement the all indexes will not be
                                % available, so this part will not ever be used.
                                %
                                % % cut Spjvs and subtract to get indexes of the
                                % % cutted yc{i,j}
                                % idx = find(Spjvs >= S(j) & Spjvs < S(j+1));
                                % tmpSpjvs = Spjvs(idx) - S(j) + 1;
                                % tmpUref = Uref(idx);
                                % if tmpSpjvs(1) ~= 1
                                %     tmpSpjvs = [1 tmpSpjvs];
                                %     % add one Uref before, because first switch was
                                %     % not at position 1
                                %     tmpUref = [Uref(idx(1)-1) tmpUref];
                                % end
                                % if tmpSpjvs(end) ~= size(yc{i,j},2) + 1
                                %     tmpSpjvs = [tmpSpjvs size(yc{i,j},2) + 1];
                                %     % no need to add Uref, it is already there
                                % end
                            end %>>>4
                            % automatically find PRs, PRe:
                            if sigconfig.PRs < 0 || sigconfig.PRe < 0
                                if find_PR_done == 0 
                                    [newPRs, newPRe] = pjvs_find_PR(yc{i,j}, tmpSpjvs, sigconfig, dbg);
                                    % set flag so the searching of PRs,PRe is not repeated in next sections:
                                    find_PR_done == 1;
                                    % set new values of PRs,PRe:
                                    sigconfig.PRs = newPRs;
                                    sigconfig.PRe = newPRe;
                                end
                            end
                            if any(diff(tmpSpjvs) == 0)
                                error('Error in calculation of PJVS step changes in function "pjvs_ident_segments".')
                            end
                            % Split the pjvs section into segments, remove PRs,PRe,MRs,MRe, calculate means, std, uA:
                            [s_y, s_mean, s_std, s_uA] = pjvs_split_segments(yc{i,j}, tmpSpjvs, sigconfig.MRs, sigconfig.MRe, sigconfig.PRs, sigconfig.PRe, dbg);
                            % Now Spjvs can be incorrect, because trailing
                            % segments (first or last one with smaller number of
                            % samples than typical) were neglected.
                            % Recreate PJVS reference values for whole sampled PJVS waveform section:
                            tmpUref = pjvs_ident_Uref(s_mean, Uref1period, dbg);

                            % debug plot %<<<2
                            if dbg.v 
                                ssec = sprintf('%03d-%03d_', dbg.section(1), dbg.section(2));
                                if dbg.pjvs_segments_first_period
                                    % plot with segments minus reference value,
                                    % for first PJVS period:
                                    figure('visible',dbg.showplots)
                                    hold on
                                    legc = {};
                                    % this limit is to correctly set limits for
                                    % plot, because NaN values cause unnecesary
                                    % empty space on right side of the plot
                                    plotlim = 0;
                                    for k = 1:numel(Uref1period)
                                        plot(1e6.*(s_y(:,k) - tmpUref(k)), '-x')
                                        legc{end+1} = sprintf('U_{ref}=%.9f', tmpUref(k));
                                        plotlim = max(plotlim, sum(~isnan(s_y(:,k))));
                                    end
                                    xlim([0.9 plotlim+0.1]);
                                    legend(legc, 'location', 'eastoutside')
                                    title(sprintf('Segment samples minus PJVS reference value\n(masked MRs, MRe, PRs, PRe)'))
                                    xlabel('Sample index')
                                    ylabel('Voltage difference (uV)')
                                    hold off
                                    fn = fullfile(dbg.plotpath, [ssec 'pjvs_segments_first_period']);
                                    if dbg.saveplotsfig saveas(gcf(), [fn '.fig'], 'fig') end
                                    if dbg.saveplotspng saveas(gcf(), [fn '.png'], 'png') end
                                    close
                                end % if dbg.pjvs_segments_first_period
                                if dbg.pjvs_segments_mean_std
                                    % plot means and std of segments minus reference value,
                                    figure('visible',dbg.showplots)
                                    hold on
                                    legc = {};
                                    plot(1e6.*(s_mean - tmpUref), 'b-x', 1e6.*s_std, 'r-x')
                                    legend('Mean of segments', 'Std. of segments')
                                    title(sprintf('Segments samples minus PJVS reference value\n(masked MRs, MRe, PRs, PRe)'))
                                    xlabel('Segment index')
                                    ylabel('Voltage (uV)')
                                    hold off
                                    fn = fullfile(dbg.plotpath, [ssec 'pjvs_segments_mean_std']);
                                    if dbg.saveplotsfig saveas(gcf(), [fn '.fig'], 'fig') end
                                    if dbg.saveplotspng saveas(gcf(), [fn '.png'], 'png') end
                                    close
                                end % if dbg.pjvs_segments_first_period
                            end % if dbg %>>>2
                            % ADEV calculation and plotting:
                            pjvs_adev(s_y, tmpUref, Uref1period, dbg);
                            % calibration of ADC:
                            ycal(i,j) = adc_pjvs_calibration(tmpUref, s_mean, s_uA, dbg);
                    else
                            % not a quantum measurement, not yet available calibration of digitizer (will be added later):
                            ycal(i,j) = empty_ycal;
                    end % if M(i, j) < 0
            end % for j = 1:columns(yc)
    end % for i = 1:rows(yc)

    % keep actual value only for DEBUG plotting:
    if dbg.v
        ycal_before_setting = ycal;
    end

    % set calibration values for all sampled data %<<<1
    % Copy calibration values from last available PJVS section to next section with DUT signal.
    for i = 1:rows(ycal)
            lastcal = empty_ycal;
            firstcalfound = 0;
            for j = 1:columns(ycal)
                    if isempty(ycal(i, j).coefs)
                            ycal(i, j) = lastcal;
                    else
                            lastcal = ycal(i, j);
                            if firstcalfound == 0
                                    % copy calibrations to previous elements:
                                    for k = 1:j-1
                                            ycal(i, k) = ycal(i,j);
                                    end % for k
                                    firstcalfound = 1;
                            end % firstcalfound = 0
                    end % isempty(ycal(i,j))
            end % for j = 1:columns(yc)
    end % for i = 1:rows(yc)

    % DEBUG plot gains and offsets vs time %<<<1
    if dbg.v
        for i = 1:rows(ycal)
                for j = 1:columns(ycal)
                        % for cycle because matlab has issues with indexing concatenation ([x].y)
                        offsets(i,j) = ycal(i,j).coefs.v(1);
                        gains(i,j) = ycal(i,j).coefs.v(2);
                        if isempty(ycal_before_setting(i,j).coefs)
                            PJVS_offsets(i,j) = NaN;
                            PJVS_gains(i,j) = NaN;
                        else
                            PJVS_offsets(i,j) = ycal(i,j).coefs.v(1);
                            PJVS_gains(i,j) = ycal(i,j).coefs.v(2);
                        end
                end % for j = 1:columns(yc)
        end % for i = 1:rows(yc)

        lfmt = {'-xr','-xg','-xb','-xk','-xc','-xy'};
        ofmt = {'or','og','ob','ok','oc','oy'};

        if dbg.adc_calibration_gains
            figure('visible',dbg.showplots)
            hold on
            plot(1e6.*(gains' - 1),      lfmt(1:size(gains,1))                    );
            plot(1e6.*(PJVS_gains' - 1), ofmt(1:size(PJVS_gains,1)), 'linewidth',2);
            title(sprintf('Calculated digitizer gains (minus 1)\nstd: %g uV', 1e6.*std(gains)));
            legend('applied gain','gain calculated from PJVS')
            xlabel('Section index')
            ylabel('Gain - 1 (uV/V)')
            % legend('all gains', 'gains calculated from PJVS');
            hold off
            fn = fullfile(dbg.plotpath, 'adc_calibration_gains');
            if dbg.saveplotsfig saveas(gcf(), [fn '.fig'], 'fig') end
            if dbg.saveplotspng saveas(gcf(), [fn '.png'], 'png') end
            close
        end % if dbg.adc_calibration_gains

        if dbg.adc_calibration_offsets
            figure('visible',dbg.showplots)
            hold on
            plot(1e6.*offsets',         lfmt(1:size(offsets,1))                    );
            plot(1e6.*PJVS_offsets',    ofmt(1:size(PJVS_offsets,1)), 'linewidth',2)
            title(sprintf('Calculated digitizer offsets\nstd: %g uV', 1e6.*std(offsets)));
            legend('applied offsets','offsets calculated from PJVS')
            xlabel('Section index')
            ylabel('Offset (uV)')
            % legend('all offsets', 'offsets calculated from PJVS');
            hold off
            fn = fullfile(dbg.plotpath, 'adc_calibration_offsets');
            if dbg.saveplotsfig saveas(gcf(), [fn '.fig'], 'fig') end
            if dbg.saveplotspng saveas(gcf(), [fn '.png'], 'png') end
            close
        end % if dbg.adc_calibration_offsets
    end % if DEBUG
end

% tests %<<<1
% missing tests... XXX

% vim settings modeline: vim: foldmarker=%<<<,%>>> fdm=marker fen ft=matlab textwidth=80 tabstop=4 shiftwidth=4
