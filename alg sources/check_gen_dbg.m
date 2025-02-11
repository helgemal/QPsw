% Generates debug structure with default values
% Is used as definition of dbg. If dbg structure is set as input, if ensures
% the dbg structure is correct and returns it.

function dbg = check_gen_dbg(dbg, switch_missing_on)
    % check inputs %<<<1
    if nargin == 0
        % create a new debug structure with any values
        dbg = struct();
    elseif nargin == 1
        switch_missing_on = 0;
    elseif nargin == 2
        if isempty(dbg)
            dbg = struct();
        end
        if isempty(switch_missing_on)
            switch_missing_on = 0;
        else
            switch_missing_on = int8(switch_missing_on);
            switch_missing_on = switch_missing_on(1);
        end
    end
    if ~isstruct(dbg)
        error('check_gen_dbg: input `dbg` has to be a structure!')
    end
    % check one field after another

    % v - debug switch %<<<1
    % integer (0)
    % If nonzero debug is enabled. Plots will be plotted.
    dbg = check_set_int8(dbg, 'v', 0 | switch_missing_on);

    % section - actual section of the data, in between multiplexer switches %<<<1
    % integer (0)
    % Used for plot titles
    dbg = check_set_int8(dbg, 'section', 0 | switch_missing_on);

    % segment - actual segment of the data, in between PJVS step changes %<<<1
    % integer (0)
    % Used for plot titles
    dbg = check_set_int8(dbg, 'segment', 0 | switch_missing_on);

    % showplots - show generated plots?
    % char ('off')
    % If on, plots are shown (if generated)
    if ~isfield(dbg, 'showplots')
        if switch_missing_on
            dbg.showplots = 'on';
        else
            dbg.showplots = 'off';
        end
    else
        if not(strcmp(dbg.showplots, 'off') || strcmp(dbg.showplots, 'on'))
            dbg.showplots = 'off';
        end
    end
    % saveplotsplt - save plots to plt files %<<<1
    % integer (0)
    % If nonzero, plots are saved as plt files
    dbg = check_set_int8(dbg, 'saveplotsplt', 0 | switch_missing_on);

    % saveplotspng - save plots to png files %<<<1
    % integer (0)
    % If nonzero, plots are saved as png files
    dbg = check_set_int8(dbg, 'saveplotspng', 0 | switch_missing_on);

    % plotpath - path to save plots
    % char ('.')
    % All plots will be saved to the specified path
    if ~isfield(dbg, 'plotpath')
        dbg.plotpath = '.';
    end

    %%
    % Plot types %<<<1
    dbg = check_set_int8(dbg, 'sections_1', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'sections_10', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'pjvs_ident_segments_10', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'pjvs_ident_segments_all', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'pjvs_ident_Uref_phase', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'pjvs_ident_Uref_all', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'pjvs_segments_first_period', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'pjvs_segments_mean_std', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'pjvs_find_PR', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'pjvs_adev', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'pjvs_adev_all', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'adc_calibration_fit', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'adc_calibration_fit_errors', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'adc_calibration_fit_errors_time', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'adc_calibration_gains', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'adc_calibration_offsets', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'demultiplexed', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'signal_amplitudes', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'signal_offsets', 0 | switch_missing_on);
    dbg = check_set_int8(dbg, 'simulator_signals', 0 | switch_missing_on);

end % function

function dbg = check_set_int8(dbg, fieldname, defaultvalue) %<<<1
% checks if fieldname exist, if so, ensure it is of int8 value, if not set to default
    if ~isfield(dbg, fieldname)
        dbg.(fieldname) = defaultvalue;
    else
        if ~isinteger(dbg.(fieldname))
            dbg.(fieldname) = int8(dbg.(fieldname));
            dbg.(fieldname) = dbg.(fieldname)(1);
        end
    end
end % function dbg, check_set_int8(dbg, fieldname, defaultvalue)
