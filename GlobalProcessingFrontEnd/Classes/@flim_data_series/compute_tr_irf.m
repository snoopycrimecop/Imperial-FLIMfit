function compute_tr_irf(obj)
    %> Transform irf depending on the data settings

    if obj.init

        % If we've got polarisation resolved data but only one irf
        % repeat over both channels
        if obj.polarisation_resolved && size(obj.irf,2) == 1
            obj.irf = repmat(obj.irf,[1 obj.n_chan]);
        end

        % Determine shift between IRFs
        if obj.polarisation_resolved

            if size(obj.t_irf,1) > 3
                irf_para = obj.irf(:,1);
                irf_perp = obj.irf(:,2);

                [c,lags] = xcorr(irf_perp,irf_para);
                [~,peak] = max(c);
                peak = lags(peak);

                yy = (peak-10):0.01:(peak+10);
                cc = spline(lags,c,yy);

                [~,peak] = max(cc);
                peak = yy(peak);

                dt = (obj.t_irf(2) - obj.t_irf(1));

                peak = peak * dt;

                obj.irf_perp_shift = -peak;

            end

        end

        % Select time points based on threshold
        t_irf_inc = true(size(obj.t_irf));
        %t_irf_inc = obj.t_irf >= obj.t_irf_min & obj.t_irf <= obj.t_irf_max;


        % downsample
        if obj.irf_downsampling > 1
            sel = (1:length(t_irf_inc))';
            sel = mod(sel,obj.irf_downsampling) == 0;
            t_irf_inc = t_irf_inc & sel;

            obj.tr_irf = convn(obj.tr_irf,ones(factor,1),'same');
        end

        obj.tr_irf = obj.irf(t_irf_inc,:);
        obj.tr_t_irf = obj.t_irf(t_irf_inc);

        if length(obj.t) > 1
            dt = obj.t(2) - obj.t(1);
            coarse_shift = round(obj.irf_perp_shift/dt);
        else
            coarse_shift = 0;
        end
        
        if obj.polarisation_resolved && size(obj.tr_irf,2) == 2
            obj.tr_irf(:,2) = circshift(obj.tr_irf(:,2),[coarse_shift 1]);
        end

        % Subtract background
        clamp = (obj.t_irf < obj.t_irf_min) | (obj.t_irf > obj.t_irf_max);

        if length(obj.irf_background) == 2
            bg = reshape(obj.irf_background,[1,2]);
            bg = repmat(bg,[length(obj.tr_t_irf),1]);
        else
            bg = repmat(obj.irf_background,[length(obj.tr_t_irf),size(obj.tr_irf,2)]);
        end

        if ~obj.afterpulsing_correction
            new_bg = bg;
            obj.tr_irf = obj.tr_irf - bg;
            obj.tr_irf(obj.tr_irf<0) = 0;
            obj.tr_irf(clamp,:) = 0;
        else
            new_bg = bg;
            z = (obj.tr_irf < bg);
            obj.tr_irf(z) = new_bg(z);
            obj.tr_irf(clamp,:) = new_bg(clamp,:); 
        end





        % Resample IRF 
        if obj.resample_irf && length(obj.tr_t_irf) > 2
            irf_spacing = obj.tr_t_irf(2) - obj.tr_t_irf(1);

            if irf_spacing > 75

                interp_min = min(obj.tr_t_irf); %#ok
                interp_max = max(obj.tr_t_irf); %#ok

                interp_t_irf = interp_min:25:interp_max;

                temp_tr_irf = obj.tr_irf;

                obj.tr_irf = zeros([length(interp_t_irf) obj.n_chan]);

                for i=1:size(obj.tr_irf,2)
                    obj.tr_irf(:,i) = interp1(obj.tr_t_irf,temp_tr_irf(:,i),interp_t_irf,'cubic');
                end
                obj.tr_t_irf = interp_t_irf;


            end
        end



        % Normalise irf so it sums to unity
        if true && size(obj.tr_irf,1) > 0 %obj.normalise_irf
            for i=1:size(obj.tr_irf,2) 
                sm = sum(obj.tr_irf(:,i));
                if sm > 0;
                    obj.tr_irf(:,i) = obj.tr_irf(:,i) / sm;
                end
            end
        end

        if obj.polarisation_resolved
            obj.tr_irf(:,1) = obj.tr_irf(:,1) * obj.g_factor;
        end

        % Shift by t0
        for i=1:size(obj.tr_irf,2)
            obj.tr_irf(:,i) = interp1(obj.tr_t_irf,obj.tr_irf(:,i),obj.tr_t_irf-obj.t0,'cubic');
        end

        obj.tr_irf(isnan(obj.tr_irf)) = 0;

    end
end