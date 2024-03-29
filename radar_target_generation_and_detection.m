clear all; close all;
clc;

%% Radar Specifications 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Frequency of operation = 77GHz
% Max Range = 200m
% Range Resolution = 1 m
% Max Velocity = 100 m/s
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%speed of light = 3e8
%% User Defined Range and Velocity of target
% *%TODO* :
% define the target's initial position and velocity. Note : Velocity
% remains contant
range_initial = 50; % unit: m
vel_initial = 50;    % unit: m/s

%% FMCW Waveform Generation

% *%TODO* :
% Design the FMCW waveform by giving the specs of each of its parameters.
% Calculate the Bandwidth (B), Chirp Time (Tchirp) and Slope (slope) of the FMCW
% chirp using the requirements above.

d_res = 1;      % unit: m
c = 3e8;        % unit: m/s
R_Max = 200;    % unit: m
v_max = 100; % given by the Radar Specifications 

Bsweep = c/(2*d_res);           % Bandwidth
Tchirp = 5.5 * 2 * R_Max/c;     % for an FMCW radar system, the sweep time should be at least 5 to 6 times the round trip time. This example uses a factor of 5.5.
Slope = Bsweep/Tchirp;          % slope of FMCW
% Operating carrier frequency of Radar 
fc = 77e9;             %carrier freq
lambda = c/fc;         % wavelength

fr_max = range2beat(R_Max,Slope,c);
fd_max =  2 * v_max/lambda;
fb_max = fr_max + fd_max;
                                                          
% The number of chirps in one sequence. Its ideal to have 2^ value for the ease of running the FFT for Doppler Estimation. 
Nd = 128;                   % #of doppler cells OR #of sent periods % number of chirps

% The number of samples on each chirp. 
Nr = 1024;                  % for length of time OR # of range cells

% Timestamp for running the displacement scenario for every sample on each
% chirp
t = linspace(0,Nd*Tchirp,Nr*Nd); %total time for samples


% Creating the vectors for Tx, Rx and Mix based on the total samples input.
Tx = zeros(1,length(t)); %transmitted signal
Rx = zeros(1,length(t)); %received signal
Mix = zeros(1,length(t)); %beat signal

%Similar vectors for range_covered and time delay.
r_t = zeros(1,length(t));   % range at time t
td  =zeros(1,length(t));    % time delay

f_fmcw = zeros(1,length(t)); %to delete

%% Signal generation and Moving Target simulation
% Running the radar scenario over the time. 

f_fmcw(1) = mod(Bsweep/Tchirp * t(1) + fc, Bsweep) + fc;
Tx(1) = cos(2*pi*f_fmcw(1)*t(1));
Rx(1) = cos(2*pi*f_fmcw(1)*(t(1) - td(1)));
for i=2:length(t)         
   
    % *%TODO* :
    %For each time stamp update the Range of the Target for constant velocity. 
    r_t(i) = range_initial + vel_initial * t(i);
    td(i) = 2*r_t(i)/c;
    
    % *%TODO* :
    %For each time sample we need update the transmitted and
    %received signal. 
% %     Tx(i) = cos(2*pi*(fc*t(i) + Slope*t(i)^2/2));
% %     Rx(i) = cos(2*pi*(fc*(t(i)-td(i)) + Slope*(t(i)-td(i))^2/2));
    
    f_fmcw(i) = mod(Bsweep/Tchirp * t(i) + fc, Bsweep) + fc;
    f_mean = (f_fmcw(i)+f_fmcw(i-1))/2;
    Tx(i) = cos(2*pi*f_mean*t(i));
    Rx(i) = cos(2*pi*f_mean*(t(i) - td(i)));
    
    % *%TODO* :
    %Now by mixing the Transmit and Receive generate the beat signal
    %This is done by element wise matrix multiplication of Transmit and
    %Receiver Signal
    Mix(i) = Tx(i).*Rx(i);
    
end

%% RANGE MEASUREMENT

% *%TODO* :
%reshape the vector into Nr*Nd array. Nr and Nd here would also define the size of
%Range and Doppler FFT respectively.

beat = reshape(Mix, [Nr, Nd]);

% *%TODO* :
%run the FFT on the beat signal along the range bins dimension (Nr) and
%normalize.

sig_fft = fft(beat, Nr);
sig_fft = sig_fft/Nr;

% *%TODO* :
% Take the absolute value of FFT output

sig_fft = abs(sig_fft);

% *%TODO* :
% Output of FFT is double sided signal, but we are interested in only one side of the spectrum.
% Hence we throw out half of the samples.
sig_fft = sig_fft(1:Nr/2,:);

%plotting the range
figure('Name','Range from First FFT')
set(gcf,'color','white');
% *%TODO* :
% plot FFT output 
Fs = 1/(Tchirp/Nr);
f = Fs*(0:Nr/2-1)/Nr;
R = f*c/(2*Slope);
plot(R, sig_fft);
hold on

axis ([0 200 0 1]);
title('Range from First FFT');
xlabel('Range(m)');


%% RANGE DOPPLER RESPONSE
% The 2D FFT implementation is already provided here. This will run a 2DFFT
% on the mixed signal (beat signal) output and generate a range doppler
% map.You will implement CFAR on the generated RDM


% Range Doppler Map Generation.

% The output of the 2D FFT is an image that has reponse in the range and
% doppler FFT bins. So, it is important to convert the axis from bin sizes
% to range and doppler based on their Max values.

Mix=reshape(Mix,[Nr,Nd]);

% 2D FFT using the FFT size for both dimensions.
sig_fft2 = fft2(Mix,Nr,Nd);

% Taking just one side of signal from Range dimension.
sig_fft2 = sig_fft2(1:Nr/2,1:Nd);
sig_fft2 = fftshift(sig_fft2);
RDM = abs(sig_fft2);
RDM = 10*log10(RDM) ;

%use the surf function to plot the output of 2DFFT and to show axis in both
%dimensions

f_r = Fs*linspace(-Nr/4, Nr/4, Nr/2)/Nr;
R = f_r*c/(2*Slope);
range_axis = R;
% % range_axis = linspace(-200,200,Nr/2)*((Nr/2)/400);

f_d = 1/(Tchirp) * linspace(-Nd/2,Nd/2,Nd)/Nd;
% % f_d = (v_max*4/lambda) * linspace(-Nd/2,Nd/2,Nd)/Nd; % vmax = lambda/(4*Tc)==> 1/Tc = (vmax*4)/lambda
% % v_res = c/(fc*2*Tchirp*Nd);
v = f_d*c/(2*fc);
doppler_axis = v;
% % doppler_axis = linspace(-100,100,Nd);

figure(2)
set(gcf,'color','white');
surf(doppler_axis,range_axis,RDM);
xlabel('doppler axis(m/s)','FontWeight','bold','fontsize',16, 'Interpreter','None');
ylabel('range_axis(m)','FontWeight','bold','fontsize',16, 'Interpreter','None');
zlabel('Amplitude','FontWeight','bold','fontsize',16, 'Interpreter','None');


%% CFAR implementation

%Slide Window through the complete Range Doppler Map

% *%TODO* :
%Select the number of Training Cells in both the dimensions.

Tr = 10;
Td = 8; 

% *%TODO* :
%Select the number of Guard Cells in both dimensions around the Cell under 
%test (CUT) for accurate estimation
Gr = 4;
Gd = 4;

% *%TODO* :
% offset the threshold by SNR value in dB

offset = 6;

% *%TODO* :
%Create a vector to store noise_level for each iteration on training cells
noise_level = zeros(Nr/2 - 2*(Tr+Gr),Nd - 2*(Td + Gd));
grid_size = (2*Tr+2*Gr+1) * (2*Td+2*Gd+1);
N_trainingCells = grid_size - (2*Gr+1)*(2*Gd+1);

% *%TODO* :
%design a loop such that it slides the CUT across range doppler map by
%giving margins at the edges for Training and Guard Cells.
%For every iteration sum the signal level within all the training
%cells. To sum convert the value from logarithmic to linear using db2pow
%function. Average the summed values for all of the training
%cells used. After averaging convert it back to logarithimic using pow2db.
%Further add the offset to it to determine the threshold. Next, compare the
%signal under CUT with this threshold. If the CUT level > threshold assign
%it a value of 1, else equate it to 0.

CFAR_sig = zeros(size(RDM));

   % Use RDM[x,y] as the matrix from the output of 2D FFT for implementing
   % CFAR

for range_index = (Tr+Gr+1) : (Nr/2 - (Tr+Gr))
    for doppler_index = (Td + Gd + 1) : (Nd - (Td+Gd))
        training = RDM(range_index - Tr - Gr : range_index + Tr + Gr, ...
            doppler_index - Td - Gd : doppler_index + Td + Gd);
        % set non-training cells to 0
        training(range_index - Gr : range_index + Gr, ...
            doppler_index - Gd : doppler_index + Gd) = 0;
        % convert decibel to power
        training = db2pow(training);
        % calculate the mean value of training cells
        training = sum(sum(training))/N_trainingCells;
        % revert averaged power to decibels
        training = pow2db(training);

% *%TODO* :
% The process above will generate a thresholded block, which is smaller 
%than the Range Doppler Map as the CUT cannot be located at the edges of
%matrix. Hence,few cells will not be thresholded. To keep the map size same
% set those values to 0. 

        %apply the offset to determine the SNR threshold
        threshold = training + offset;
        % apply threshold to the CUT
        if RDM(range_index, doppler_index) > threshold
            CFAR_sig(range_index, doppler_index) = 1;
        end
    end
end



% *%TODO* :
%display the CFAR output using the Surf function like we did for Range
%Doppler Response output.
figure,surf(doppler_axis,range_axis,CFAR_sig);
set(gcf,'color','white');
colorbar;
xlabel('doppler axis(m/s)','FontWeight','bold','fontsize',16, 'Interpreter','None');
ylabel('range_axis(m)','FontWeight','bold','fontsize',16, 'Interpreter','None');
zlabel('CFAR Threshold','FontWeight','bold','fontsize',16, 'Interpreter','None');

figure,surf(doppler_axis,range_axis,CFAR_sig.*RDM);
set(gcf,'color','white');
colorbar;
xlabel('doppler axis(m/s)','FontWeight','bold','fontsize',16, 'Interpreter','None');
ylabel('range_axis(m)','FontWeight','bold','fontsize',16, 'Interpreter','None');
zlabel('Amplitude','FontWeight','bold','fontsize',16, 'Interpreter','None'); 
 
