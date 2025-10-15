%% Lab6: Bandeko
clearvars; clc; clear; close all;

%% Steg 1: Läs in ljudfilen
[orig, Fs] = audioread('AnalogRytm_120BPM.wav'); 
sound(orig, Fs); 
disp('Originalljudet spelas...');

%% Steg 2:  (Aspekt 1: Delay)
% Skapar upprepade eko genom feedback och delay
delayTime = 0.3;   
feedback = 0.5;    
mix = 0.5;         

delaySamples = round(delayTime * Fs);
y = orig;

for n = (delaySamples + 1):length(orig)
    y(n,:) = y(n,:) + feedback * y(n - delaySamples,:);
end

y_bandecho = (1 - mix) * orig + mix * y;

%% Steg 3:  (Aspekt 2: Filter)
% Dämpar höga frekvenser, dvs lågpassfilter
fc = 5000; % cutoff
[b, a] = butter(1, fc/(Fs/2), 'low');
y_filtered = filter(b, a, y_bandecho);

%% Steg 4: Delay med nollor och normalisering (Aspekt 1: förstärkt)
% Skapar extra upprepningar med rätt timing och nivåer
delayTime_sec = 0.5; 
delaySamples2 = round(delayTime_sec * Fs);

x1 = [y_filtered; zeros(delaySamples2, size(y_filtered,2))];
x2 = [zeros(delaySamples2, size(y_filtered,2)); y_filtered];

y_delay = x1 + 0.5*x2;          
y_delay = y_delay / max(abs(y_delay(:)));

%% Steg 5: (Aspekt 3: Reverb)
% Simulerar fjäderreverb med tre seriekopplade allpass-filter(shoereder-reverb)
allpassDelays = [142, 107, 379]; % antal samples att fördröja signalen med
allpassGains = [0.7, 0.7, 0.7]; % hur mycket av fördröjd signal som körs tillbaka
y_reverb = y_delay;

for k = 1:length(allpassDelays)
    D = allpassDelays(k);
    g = allpassGains(k);
    y_temp = zeros(size(y_reverb));
    for n = D+1:length(y_reverb)
        y_temp(n,:) = -g*y_reverb(n,:) + y_reverb(n-D,:) + g*y_temp(n-D,:);
    end
    y_reverb = y_temp;
end

reverbMix = 0.3;
y_final = (1 - reverbMix)*y_delay + reverbMix*y_reverb;
y_final = y_final / max(abs(y_final(:)));

%% Steg 6: Dynamikbearbetning (Aspekt 4: Förstärkning)

gainFactor = 2; 
y_final = y_final * gainFactor; % Ökar ljudets nivå med gainFactor.
y_final = y_final / max(abs(y_final(:))); % normalisera

%% (Aspekt 5: Distorsion)
% Mjuk överstyrning
distLevel = 5;
y_dist = (distLevel*y_final) ./ (1 + distLevel*abs(y_final)); % förstärker signalen / dämpar höga amp
y_dist = y_dist / max(abs(y_dist(:)));  %normalisera

%% (Aspekt 6a: Expansion)
% Ökar skillnaden mellan svaga och starka ljud
expFactor = 1.5; % styrkan på expansionen, kan justeras
y_expand = y_final;
for n = 1:length(y_expand)
    y_expand(n,:) = y_expand(n,:) .* abs(y_expand(n,:)).^expFactor;
end
y_expand = y_expand / max(abs(y_expand(:)));

%% (Aspekt 6b: Kompression)
% Minskar skillnaden mellan svaga och starka ljud
y_compress = y_final;
for n = 1:length(y_compress)
    y_compress(n,:) = y_compress(n,:) .* (2 - abs(y_compress(n,:)));
end
y_compress = y_compress / max(abs(y_compress(:)));

%% Steg 7: Slutresultat
sound(y_final, Fs);
audiowrite('MyBandEcho_Final.wav', y_final, Fs);
disp('SKAPAT MyBandEcho_Final.wav!');

%% Steg 8: Visualisering
if size(y_final,2) > 1
    y_mono = mean(y_final,2);
else
    y_mono = y_final;
end

figure;
plot((1:length(y_mono))/Fs, y_mono);
xlabel('Tid (s)'); ylabel('Amplitud');
title('Vågform av slutligt bandeko-ljud');
grid on;

figure;
window = 1024; noverlap = 512; nfft = 2048;
spectrogram(y_mono, window, noverlap, nfft, Fs, 'yaxis');
ylim([0 10]);
colorbar;
title('Spektrogram av slutligt bandeko-ljud');

%% Steg 9: RMS
% Genomsnittliga styrka eller energinivå
rms_orig = rms(orig);
rms_final = rms(y_final);
disp(['RMS originalljud: ', num2str(rms_orig)]);
disp(['RMS slutligt ljud: ', num2str(rms_final)]); % visar fördubllat energinivå av orginal
disp('Done!');
