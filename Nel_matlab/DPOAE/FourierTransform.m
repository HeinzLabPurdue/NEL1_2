function [Amplitude_Spectrum, Phase_Spectrum_deg, freq_vector_Hz] = FourierTransform(signal, SamplingRate_Hz)% File: FourierTransform.m% Created by: M. Heinz% Created on: Feb 13, 2006%% Usage: [Amplitude_Spectrum, Phase_Spectrum_deg, freq_vector_Hz] = FourierTransform(signal, SamplingRate_Hz)%% This function calculates the Fourier Transform (Amplitude and Phase spectra) for a given waveform and sampling rate.% % Input Parameters:%   signal: waveform (any units)%   SamplingRate_Hz: sampling rate (in samples per sec, i.e., Hz)%% Output Variables:%   Amplitude_Spectrum: (in same units as Amplitude)%   Phase_Spectrum_deg: (in degrees)%   freq_vector_Hz: frequency vector (in Hz)%%%% FFTNfft=2^ceil(log2(SamplingRate_Hz)); % Use next highest power of 2 re: SR (will give frequency spacing less than 1 Hz)FourierTransf=fft(signal,Nfft);% Nfft=length(FourierTransf);Amplitude_Spectrum=abs(FourierTransf)/Nfft;   % Need to normalize by number of points in FFTPhase_Spectrum_deg=angle(FourierTransf)/(2*pi)*360;freq_vector_Hz=(0:Nfft-1)*SamplingRate_Hz/Nfft;% Take away negative frequenciesfreq_inds=find(freq_vector_Hz <= SamplingRate_Hz/2);Amplitude_Spectrum=Amplitude_Spectrum(freq_inds);Amplitude_Spectrum(2:end)=Amplitude_Spectrum(2:end)*2;Phase_Spectrum_deg=Phase_Spectrum_deg(freq_inds);freq_vector_Hz=freq_vector_Hz(freq_inds);zero_inds=find(Amplitude_Spectrum<0.01*max(Amplitude_Spectrum));Phase_Spectrum_deg(zero_inds)=NaN;