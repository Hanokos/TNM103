%% =======================================
%% Fasvokoder + Granulärsyntes (TNM103) - Full version
%% =======================================
clearvars;
close all;
clc;

%% -------------------------
%% Läs in ljudfil automatiskt
%% -------------------------
file = 'C:\LJUDTEKNIK\Lab7\Piano.wav';
if ~isfile(file)
    error(['Ljudfilen hittades inte: ', file]);
end

[originalSound, fs] = audioread(file);
disp(['Laddade in ljudfil: ', file]);

% Mono om stereo
if size(originalSound,2) > 1
    originalSound = originalSound(:,1);
end

% Normalisera
originalSound = originalSound / max(abs(originalSound));

%% =======================================
%% DEL 1: Fasvokoder – tempo & pitch
%% =======================================

speed = 1;           % tempo
pitch = 1.5;         % pitch

windowSize = round(0.05 * fs);
stepSize = round(windowSize * speed);

newFrame = zeros(round(length(originalSound) * (windowSize / stepSize) + windowSize), 1);
k = 1;
for i = 0:stepSize:(length(originalSound)-1)
    for j = 0:(windowSize-1)
        newFrame(k) = i + j + 1;
        k = k + 1;
    end
end

newFrame = newFrame(newFrame > 0);
newFrame = newFrame(newFrame <= length(originalSound));
phaseVocodedSound = interp1(1:length(originalSound), originalSound, newFrame, 'linear');

if pitch == 1
    Fs2 = fs;
else
    Fs2 = round(fs * pitch);
end

% Spela upp original
disp('Spelar upp original...');
sound(originalSound, fs);
pause(length(originalSound)/fs + 1);

% Spela upp pitch-shiftat ljud
disp(['Spelar upp pitch-shiftat ljud (speed=1, pitch=', num2str(pitch), ')...']);
sound(phaseVocodedSound, Fs2);
pause(length(phaseVocodedSound)/Fs2 + 1);

%% Ändra både tempo och pitch
speed = 0.8;
pitch = 0.8;
windowSize = round(0.05 * fs);
stepSize = round(windowSize * speed);

newFrame = zeros(round(length(originalSound) * (windowSize / stepSize) + windowSize), 1);
k = 1;
for i = 0:stepSize:(length(originalSound)-1)
    for j = 0:(windowSize-1)
        newFrame(k) = i + j + 1;
        k = k + 1;
    end
end
newFrame = newFrame(newFrame > 0);
newFrame = newFrame(newFrame <= length(originalSound));
phaseVocodedSound = interp1(1:length(originalSound), originalSound, newFrame, 'linear');

if pitch == 1
    Fs2 = fs;
else
    Fs2 = round(fs * pitch);
end

% Visa vågformer
figure;
subplot(2,1,1); plot(originalSound); title('Original'); xlabel('Samples'); ylabel('Amplitude');
subplot(2,1,2); plot(phaseVocodedSound); title(['Fasvokoder: speed = ', num2str(speed), ', pitch = ', num2str(pitch)]); xlabel('Samples'); ylabel('Amplitude');

disp(['Spelar upp fasvokoder-ljud: speed = ', num2str(speed), ', pitch = ', num2str(pitch)]);
sound(phaseVocodedSound, Fs2);
pause(length(phaseVocodedSound)/Fs2 + 1);

%% =======================================
%% DEL 2: Granulärsyntes – skapa fönster
%% =======================================

grainSize = 0.4;          % i sekunder, ändra för experiment
speedFactor = 1;          
numberRepeats = 2;        

frameSize = floor(grainSize * fs);      
decomposeHopLength = round(frameSize/2); % 50% överlapp

numFrames = ceil((length(originalSound) - frameSize)/decomposeHopLength) + 1;
frameMatrix = zeros(frameSize, numFrames);
hannWindow = hann(frameSize);

for n = 0:(numFrames-1)
    startIdx = n*decomposeHopLength + 1;
    endIdx = startIdx + frameSize - 1;
    if endIdx > length(originalSound)
        thisFrame = zeros(frameSize,1);
        validLength = length(originalSound) - startIdx + 1;
        thisFrame(1:validLength) = originalSound(startIdx:end);
    else
        thisFrame = originalSound(startIdx:endIdx);
    end
    frameMatrix(:, n+1) = thisFrame .* hannWindow;
end

disp(['Antal frames skapade: ', num2str(numFrames)]);
figure;
plot(frameMatrix(:,1)); title('Första fönstret med Hann-fönster'); xlabel('Samples'); ylabel('Amplitude');

%% =======================================
%% DEL 3: Återskapa ljudet från grains
%% =======================================

reconstructHopLength = round(decomposeHopLength * speedFactor);
reconstructedSound = zeros(round(length(originalSound) * numberRepeats * max(1, speedFactor)), 1);

countingFrames = 1;
for currentFrame = 1:numFrames
    for repeat = 1:numberRepeats
        startIndex = (countingFrames - 1) * reconstructHopLength + 1;
        stopIndex = startIndex + frameSize - 1;
        if stopIndex > length(reconstructedSound)
            stopIndex = length(reconstructedSound);
        end
        frameLength = min(frameSize, stopIndex - startIndex + 1);
        reconstructedSound(startIndex:startIndex+frameLength-1) = ...
            reconstructedSound(startIndex:startIndex+frameLength-1) + frameMatrix(1:frameLength, currentFrame);
        countingFrames = countingFrames + 1;
    end
end

% Trimma nollor och normalisera
reconstructedSound = reconstructedSound(1:find(reconstructedSound, 1, 'last'));
reconstructedSound = reconstructedSound / max(abs(reconstructedSound));

% Visa vågform för återskapat ljud
figure;
plot(reconstructedSound);
title('Återskapat ljud från grains');
xlabel('Samples');
ylabel('Amplitude');

disp('Spelar upp återskapat ljud...');
sound(reconstructedSound, fs);
pause(length(reconstructedSound)/fs + 1);

%% =======================================
%% DEL 4: Experimentera med grains
%% =======================================

% 1. Grains baklänges
reconstructedSoundRevGrains = zeros(size(reconstructedSound));
countingFrames = 1;
for currentFrame = 1:numFrames
    flippedGrain = flipud(frameMatrix(:, currentFrame));
    for repeat = 1:numberRepeats
        startIndex = (countingFrames - 1) * reconstructHopLength + 1;
        stopIndex = startIndex + frameSize - 1;
        if stopIndex > length(reconstructedSoundRevGrains)
            stopIndex = length(reconstructedSoundRevGrains);
        end
        frameLength = min(frameSize, stopIndex - startIndex + 1);
        reconstructedSoundRevGrains(startIndex:startIndex+frameLength-1) = ...
            reconstructedSoundRevGrains(startIndex:startIndex+frameLength-1) + flippedGrain(1:frameLength);
        countingFrames = countingFrames + 1;
    end
end
reconstructedSoundRevGrains = reconstructedSoundRevGrains / max(abs(reconstructedSoundRevGrains));

figure;
plot(reconstructedSoundRevGrains);
title('Återskapat ljud: grains baklänges');
xlabel('Samples');
ylabel('Amplitude');

disp('Spelar upp grains baklänges...');
sound(reconstructedSoundRevGrains, fs);
pause(length(reconstructedSoundRevGrains)/fs + 1);

% 2. Grains i baklänges ordning
reconstructedSoundBackOrder = flipud(reconstructedSound);

figure;
plot(reconstructedSoundBackOrder);
title('Återskapat ljud: grains i baklänges ordning');
xlabel('Samples');
ylabel('Amplitude');

disp('Spelar upp grains i baklänges ordning...');
sound(reconstructedSoundBackOrder, fs);
pause(length(reconstructedSoundBackOrder)/fs + 1);

% 3. Grains i slumpad ordning
randFrames = randperm(numFrames);
randomSound = zeros(size(reconstructedSound));
countingFrames = 1;
for currentFrame = 1:numFrames
    for repeat = 1:numberRepeats
        startIndex = (countingFrames - 1) * reconstructHopLength + 1;
        stopIndex = startIndex + frameSize - 1;
        if stopIndex > length(randomSound)
            stopIndex = length(randomSound);
        end
        frameLength = min(frameSize, stopIndex - startIndex + 1);
        randomSound(startIndex:startIndex+frameLength-1) = ...
            randomSound(startIndex:startIndex+frameLength-1) + frameMatrix(1:frameLength, randFrames(currentFrame));
        countingFrames = countingFrames + 1;
    end
end
randomSound = randomSound / max(abs(randomSound));

figure;
plot(randomSound);
title('Återskapat ljud: grains i slumpad ordning');
xlabel('Samples');
ylabel('Amplitude');

disp('Spelar upp grains i slumpad ordning...');
sound(randomSound, fs);
pause(length(randomSound)/fs + 1);

% 4. Pitch på återskapade ljud
newPitch = 2.2;
Fs2 = round(fs * newPitch);

figure;
plot(reconstructedSound);
title(['Återskapat ljud: ny pitch = ', num2str(newPitch)]);
xlabel('Samples');
ylabel('Amplitude');

disp(['Spelar upp återskapat ljud med ny pitch: ', num2str(newPitch)]);
sound(reconstructedSound, Fs2);
pause(length(reconstructedSound)/Fs2 + 1);

%% =======================================
%% Kommentar om artefakter
%% =======================================
% När grains/fft blandas ihop kan fasproblem uppstå, särskilt vid ändrad hastighet eller pitch.
% Detta kan ge hörbara klick, smattrande ljud eller extra frekvenser.
% Hanningfönster minskar plötsliga amplitudehoppar, men lösningen är fortfarande approximativ.
