%% Enkel "fulvokoder" med speed, windowSize och stepSize
clearvars;
close all;
clc;

%% Läs in ljudfil
[file, path] = uigetfile({'*.wav'}, 'Välj en ljudfil');
if isequal(file,0)
    disp('Ingen fil vald');
    return;
end
[originalSound, fs] = audioread(fullfile(path, file));

% Mono om stereo
if size(originalSound,2) > 1
    originalSound = originalSound(:,1);
end

%% Parametrar
speed = 2;  % 1 = normalhastighet, 0.5 = halv hastighet, 2 = dubbel hastighet
windowSize = round(0.05 * fs); % 5% av samplingsfrekvensen
stepSize = round(windowSize * speed); % Stegstorlek beroende på hastighet

%% Skapa index-array för nya ljudet
newFrame = zeros(round(length(originalSound) * (windowSize / stepSize) + windowSize), 1);
k = 1; % index för newFrame
for i = 0:stepSize:(length(originalSound)-1)
    for j = 0:(windowSize-1)
        newFrame(k) = i + j + 1;
        k = k + 1;
    end
end

% Ta bort nollor
ix = newFrame > 0;
newFrame = newFrame(ix);

% Kontrollera att alla index är inom originalSound
ix = newFrame <= length(originalSound);
newFrame = newFrame(ix);

%% Skapa nytt ljud baserat på index-array
phaseVocodedSound = originalSound(newFrame);

%% Visa vågformer
figure;
subplot(2,1,1);
plot(originalSound);
title('Original');
xlabel('Samples');
ylabel('Amplitude');

subplot(2,1,2);
plot(phaseVocodedSound);
title(['Ny ljudvektor med speed = ', num2str(speed)]);
xlabel('Samples');
ylabel('Amplitude');

%% Spela upp ljud
disp('Spelar upp original...');
sound(originalSound, fs);
pause(length(originalSound)/fs + 1);

disp('Spelar upp nytt ljud...');
sound(phaseVocodedSound, fs);
