function [U, Delays, PixResol ] = load_PicoQuant_bin(filename,precision)

    fid = fopen(filename,'r');

    PixX = fread(fid,1,'uint32');
    PixY = fread(fid,1, 'uint32');
    PixResol = fread(fid,1, 'single'); % microns?
    TCSPCChannels = fread(fid,1, 'uint32');
    TimeResol = fread(fid,1, 'single');

    U = zeros(PixX,PixX,TCSPCChannels);

        switch precision
            case {'int8', 'uint8'}
                U = uint8(U);
            case {'uint16','int16'}
                U = uint16(U);
            case {'uint32','int32'}
                U = uint32(U);
            case {'single'}
                U = float(U);
        end                                

    for y = 1:PixY
        for x = 1:PixX
            U(x,y,:) = fread(fid,TCSPCChannels,precision);
        end;
    end; 

    Delays = ((1:TCSPCChannels)-1)*TimeResol;

    if TimeResol < 1 Delays = Delays*1e3; end; %to picoseconds

end