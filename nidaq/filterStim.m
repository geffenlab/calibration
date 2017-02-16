function filterStim( filt, fromFile, toFile )
% filterStim( filt, fromFile, toFile )
%   Filter a .wav file that may be too long to fit in memory, taking care
%   to avoid filter artifacts around the edges of the chunks as they are
%   filtered. Optionally wrap the file so that there are no artifacts at
%   the very start either.

% if nargin < 4
%     wrap = 0;
% end

maxSamps = 14000000; % Adjust as necessary based on memory size
% Beware of increasing too much: see the determination of chunkSize.
overlap = floor(length(filt) / 2); % Hopefully eliminates filter edge artifacts

% % The goal is for <overlap> to be larger than the section of the filter
% % that contains the bulk of its amplitude. Issue a warning if <overlap>
% % is less than the length of the filter.
% if overlap < length(filt), 
%     disp('filterStim: Warning: possibly insufficient overlap');
% end

siz = wavread(fromFile, 'size');
samps = siz(1);
channels = siz(2);
totalWritten = 0;

if samps <= maxSamps
    [noise, fs, nbits] = wavread(fromFile);
    noise(:,1) = conv(noise(:,1), filt, 'same');
%     if wrap
%         noise(:,1) = wrapFilter(filt, noise(:,1));
%     else
%         noise(:,1) = filter(filt, 1, noise(:,1)); % Ignore ttl channel
%     end
    wavwrite(noise, fs, nbits, toFile);
else
%     numChunks = ceil(samps / maxSamps);
%     blockSize = ceil(samps / numChunks); % size of data to read
%     from = 1; to = blockSize;
%     
%     fid = []; fmt = [];
%     
%     while to <= samps,
%         if from == 1
%             fMode = 1;
%         elseif to == samps
%             fMode = 4;
%         else
%             fMode = 3;
%         end
%         
%         [noise, fs, nbits] = wavread(fromFile, [from to]);
%         noise(:,1) = conv(noise(:,1), filt, 'same');
%         [fid fmt] = wavwriteStim(noise, fs, nbits,...
%             toFile, fMode, samps, fid, fmt);
%         
%         totalWritten = totalWritten + to - from + 1;
%         
%         if to == samps
%             break;
%         end
%         
%         from = from + blockSize;
%         to = min(to+blockSize, samps);
%     end
    numChunks = ceil((samps-overlap) / (maxSamps-2*overlap));
    blockSize = maxSamps; %ceil(samps / numChunks) % size of data to read
    chunkSize = blockSize - 2 * overlap; % size of useful data
    
    from = 1;
    to = blockSize;
    fid = []; fmt = [];
    
    for chunk = 1:numChunks
        if from == 1
            useFrom = 1;
        else
            useFrom = overlap + 1;
        end
        
        if to == samps
            useTo = to - from + 1;
        else
            useTo = to - from - overlap + 1;
        end
        
        if chunk == 1
            fMode = 1;
        elseif chunk == numChunks
            fMode = 4;
        else
            fMode = 3;
        end
        
        [noise, fs, nbits] = wavread(fromFile, [from to]);
        noise(:,1) = conv(noise(:,1), filt, 'same');
        noise = noise( useFrom:useTo, : );
        [fid,fmt] = wavwriteStim(...
            noise, fs, nbits, toFile, fMode, samps, fid, fmt);
        
        from = from + chunkSize;
        to = min(to + chunkSize, samps);
        
        totalWritten = totalWritten + useTo - useFrom + 1;
    end
end

totalWritten