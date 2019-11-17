# Radar Target Generation and Detection

[//]: # (Image References)
[image0]: ./graphs/projectLayout.png "layout"
[image1]: ./graphs/fmcwWaveformDesign.png "fmcw waveform"
[image2]: ./graphs/initialSpeedRange.png "initial speed and range"
[image3]: ./graphs/NdNrt.png "Nd, Nr, time"
[image4]: ./graphs/TxRxGeneration.png "signal generation"
[image5]: ./graphs/rangeMeasurement.png "range measurement"
[image6]: ./graphs/rangeResult.jpg "range measurement result"
[image7]: ./graphs/FFT2DCode.png "2D FFT Code"
[image8]: ./graphs/dopplerFFTResult.jpg "doppler FFT result"
[image9]: ./graphs/CFARCode.png "CFAR code"
[image10]: ./graphs/CFARThresholdPlot.png "CFAR threshold plot code"
[image11]: ./graphs/CFARTheshold.jpg "CFAR threshold"
[image12]: ./graphs/CFARApplied.jpg "CFAR threshold applied"


This project is to use frequency modulated continuous-wave (FMCW) radar and related post-processing techniques to detect the location and speed of object (e.g. car). The following is an overview of the project.

![alt text][image0]

* Configure the FMCW waveform based on the system requirements. 
* Define the range and velocity of target and simulate its displacement.
* For the same simulation loop process the transmit and receive signal to determine the beat signal
* Perform Range FFT on the received signal to determine the Range
* Towards the end, perform the CFAR processing on the output of 2nd FFT to display the target.

## project rubric 

#### FMCW Waveform Design
**Using the given system requirements, design a FMCW waveform. Find its Bandwidth (B), chirp time (Tchirp) and slope of the chirp.**   

Below is Radar speicification given by the project
  
%% Radar Specifications   
%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% Frequency of operation = 77GHz  
% Max Range = 200m  
% Range Resolution = 1 m  
% Max Velocity = 100 m/s  
%%%%%%%%%%%%%%%%%%%%%%%%%%%  

* The sweep bandwidth can be determined according to the range resolution and the sweep slope is calculated using both sweep bandwidth and sweep time.  
**_Bandwidth(Bsweep) = speed of light / (2 x rangeResolution)_**.   

* The sweep time can be computed based on the time needed for the signal to travel the unambiguous maximum range. In general, for an FMCW radar system, the sweep time should be at least 5 to 6 times the round trip time. This project uses a factor of 5.5.  
**_Tchirp = 5.5 x 2 x Rmax/c_**  
* The slope of the chirp signal can be calculated as below   
**_Slope = Bandwidth/Tchirp_**

It's implemented in the Matlab code
![alt text][image1]

#### Simulation Loop
**Simulate Target movement and calculate the beat or mixed signal for every timestamp.**  
* The initial range and velocity is specified in the code 
  ![alt text][image2]   

* The number of chirps Nd and the number of samples on each chirp Nr are specified in the code. Time stamp for every sample on each chirp is initialized. Also Tx, Rx, Mix singals and range, time delay and fcmw frequency at time t are initialized with 0 values.
![alt text][image3]     

* The Tx and Rx signal generation is implemented in the code as below
  ![alt text][image4]    
       

#### Range FFT (1st FFT)
**Implement the Range FFT on the Beat or Mixed Signal and plot the result.** 
Below are range FFT operation steps 
* Implement the 1D FFT on the Mixed Signal 
* Reshape the vector into Nr*Nd array. 
* Run the FFT on the beat signal along the range bins dimension (Nr) 
* Normalize the FFT output. 
* Take the absolute value of that output.
* Keep one half of the signal
* Plot the output
* There should be a peak at the initial position of the target

The code of range FFT on the beat (mixed) signal is implemented in the code below
  ![alt text][image5]   

The resul of range FFT on the beat (mixed) signal is shown as below. The graph shows all the Nd range FFT results. The peak values from Nd range FFT are all equal to the initial range specified in the code - `vel_initial = 50  % unit: m/s`.

  ![alt text][image6]   

#### 2D CFAR
**Implement the 2D CFAR process on the output of 2D FFT operation, i.e the Range Doppler Map.**

The code of 2D FFT operation is implemented below
    ![alt text][image7]  

The result of 2D FFT result (Range Doppler Map) is shown below. As you can see, there are noises in it.
    ![alt text][image8]

Next, 2D CFAR (Constant false alarm rate) will be implemented. Its process is listed as below  

* Determine the number of Training cells for each dimension. Similarly, pick the number of guard cells.
* Slide the cell under test across the complete matrix. Make sure the CUT has margin for Training and Guard cells from the edges.
* For every iteration sum the signal level within all the training cells. To sum convert the value from logarithmic to linear using db2pow function. 
* Average the summed values for all of the training cells used. After averaging convert it back to logarithmic using pow2db.
* Further add the offset to it to determine the threshold. 
* Next, compare the signal under CUT against this threshold. 
* If the CUT level > threshold assign it a value of 1, else equate it to 0.  

The process above will generate a thresholded block, which is smaller than the Range Doppler Map as the CUTs cannot be located at the edges of the matrix due to the presence of Target and Guard cells. Hence, those cells will not be thresholded. To keep the map size same as it was before CFAR, equate all the non-thresholded cells to 0. 

The 2D CFAR is implemented in the code as below. You can find how I defined the training, guard cells for both range and doppler dimensions. Also the offset for threshold by SNR value in dB `Tr = 10; Td = 8; offset = 6;`

   ![alt text][image9]
   ![alt text][image10]


The 2D CFAR threshold generated by the code is shown as graph below. It compares the signal under CUT(Cell Under Test) against this threshold. If the CUT level > threshold assign it a value of 1, else equate it to 0.
   ![alt text][image11]

As a final step, I applied the 2D CFAR threshold to the Range Doppler Map. The filtered result is shown as below
   ![alt text][image12]

#### Create a CFAR README File  
Here is a README file for the project. Thanks for your time to read it.
