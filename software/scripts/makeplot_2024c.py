#!/usr/bin/env python3

import os
import glob
import re
import datetime
import matplotlib.pyplot as plt
import pyrogue.utilities.fileio as fileio
import numpy as np
import os
import time
import struct

def find_latest_dat_files(directory):
    dat_files = glob.glob(os.path.join(directory, 'data_*.dat'))

    if not dat_files:
        return None, None
    
    # 日時を取得し、最新のものを見つける
    latest_file = max(dat_files, key=os.path.getctime)
    latest_datetime = datetime.datetime.strptime(os.path.basename(latest_file)[5:20], '%Y%m%d_%H%M%S')
    
    # 最新のファイルと一個前のファイルを見つける
    previous_files = [file for file in dat_files if file != latest_file]
    previous_files = [file for file in previous_files if datetime.datetime.strptime(os.path.basename(file)[5:20], '%Y%m%d_%H%M%S') < latest_datetime]
    previous_file = max(previous_files, key=lambda x: datetime.datetime.strptime(os.path.basename(x)[5:20], '%Y%m%d_%H%M%S')) if previous_files else None
    
    return latest_file, previous_file

def datfile(filename):
    # Waveforms variables to be filled 
    ampFault = { i : []  for i in range(4) }  
    recordtime = []
    
    # Open the .dat file
    with fileio.FileReader(files=filename) as fd:
        i=0
        # Loop through the file data
        for header,data in fd.records():
    
            # Check if there is a 8-byte header in the frame
            if (header.flags==0):
                hdrOffset = 8
                hdr = struct.unpack("<d", data[:8])[0]
                timestamp = time.localtime(hdr)
                # Define the desired format string (replace with your preferred format)
                # Some common format specifiers:
                # %Y - Year with century
                # %m - Month as a decimal number (01-12)
                # %d - Day of the month as a decimal number (01-31)
                # %H - Hour in 24-hour format (00-23)
                # %M - Minute (00-59)
                # %S - Second (00-59)
                formatted_time = time.strftime('%Y-%m-%d %H:%M:%S', timestamp)
                #print( f'CH={header.channel}: Event Timestamp in human-readable format: {formatted_time}' )
                if i%4==0:
                    recordtime.append(formatted_time)
                i+=1
            else:
                hdrOffset = 0
                print( 'No timestamp header detected' )
            
            # Check for error in frame
            if (header.error>0):
                # Look at record header data
                print(f"Processing record. Total={fd.totCount}, Current={fd.currCount}")
                print(f"Record size    = {header.size}")
                print(f"Record channel = {header.channel}")
                print(f"Record flags   = {header.flags:#x}")
                print(f"Record error   = {header.error:#x}")
    
            # Check if AMP Fault waveform
            elif (header.channel < 16) and (header.channel >= 12):
                ampFault[header.channel-12].append(data[hdrOffset:].view(np.int16))

            # Else undefined stream index
            #else:
                #print( f'UNDEFINED DATA STREAM[{header.channel}]!!!')
    return ampFault, recordtime

def parse_and_plot(filename):
    print(f'Processing {filename} ...')
    ampFault, recordtime=datfile(filename)
    print(f'filename: {filename}')
    print(f'Recorded time: {recordtime[0]}')
    recordtime=recordtime[0].replace(' ','_').replace(':','-')

    X_sum=ampFault[0][0]
    X_delta=ampFault[1][0]
    Y_sum=ampFault[2][0]
    Y_delta=ampFault[3][0]
    
    ###########################################################################################################
    # Detect the bunch and determine the index where the bunch is located.
    # This firmware records peak value of each 5120 RF buckets. But not all buckets contain bunch. 
    # Since I'm testing a new firmware which detect bunch oscillation and issue a trigger itself from 2024c, 
    # the trigger timing is not constant for each abort event.
    # Therefore it is not guaranteed that 101 turns are recorded for all events.
    ###########################################################################################################
    #find first abort gap
    start=0
    for i in range(0,2560):
        if i==2560:
            print("data is invalid")
            return
        if max(X_sum[i:i+50])<500:
            start=i+50
            break

    # determine the number of turns recorded in this file
    end=0
    for i in range(0,205):
        if start+(i+1)*2560 > len(X_sum):
            print('Data is invalid')
            return
        if np.sum(X_sum[start+i*2560:start+(i+1)*2560]) < 256000:
            end=i
            break
    if end%2==1:
        start=start+2560
        turn=end//2
    elif end%2==0:
        turn=end//2
            

    def bunchindex(threshold,waveform):
        bunch_index=[]                                                                                                                                                                                                                                                         
        for i in range(5120):
            if waveform[start+i]>threshold:
                bunch_index.append(start+i)

        if len(bunch_index)==0:
            print("Data is invalid")
            return bunch_index

        return np.array(bunch_index)

    bunch_index=bunchindex(1000,X_sum)

    if len(bunch_index)==0 or turn<=10:
        print("end process")
        return 0

    os.makedirs(f'/mnt/SBOR/RFSoC/{recordtime}',exist_ok=True)
    print(f'Num of bunch : {len(bunch_index)}') # If num of bunch is weired, threshod must be adjusted.

    ###########################################################################################################
    # Using 'bunch_index', calculate and store bunch position and bunch charge in 2d array 'DV(UV)' and 'charge_D(U)'.
    # Position is calculated by delta/sum * 16.58/5 (mm).
    # The row of these 2D array corresponds to bunch index, and colum corresponds to the number of turn.
    # If num of bunch is 2346 and num of turn is 100, the shape of 'X', 'Y' and 'charge' is 2346x100.
    ###########################################################################################################
    X=[]
    Y=[]
    charge=[]
    for j in bunch_index:
        certain_bunch_X=[]
        certain_bunch_Y=[]
        certain_bunch_charge=[]
        for i in range(turn):
            tbt_0=X_sum[j+5120*i]
            tbt_1=X_delta[j+5120*i]
            tbt_2=Y_sum[j+5120*i]
            tbt_3=Y_delta[j+5120*i]
            certain_bunch_Y.append(tbt_3/tbt_2*16.58/5)
            certain_bunch_X.append(tbt_1/tbt_0*16.58/5)
            certain_bunch_charge.append(tbt_0+tbt_2)
        X.append(np.array(certain_bunch_X))
        Y.append(np.array(certain_bunch_Y))
        charge.append(np.array(certain_bunch_charge))
    X=np.array(X)
    Y=np.array(Y)
    charge=np.array(charge)

    #Subtract the average of the first two turns' positions to make the results easier to see.
    mean=np.mean(X[:,0:2],axis=1)
    X=X-mean[:,np.newaxis]
    mean=np.mean(Y[:,0:2],axis=1)
    Y=Y-mean[:,np.newaxis]
    #Normalize by the average of the first two turns' charge to make the results easier to see.
    charge_mean=np.mean(charge[:,0:2],axis=1)
    charge=charge/charge_mean[:,np.newaxis]


    ######################################
    # make plot of last 10 turns
    ######################################
    #make x axis                                                                                                                                                                                                                                                                
    bunch_index_10=[]
    for i in range(10):
        bunch_index_10.append(bunch_index-bunch_index[0]+5120*i)
    x_axis=np.concatenate(bunch_index_10)/5120
    x_axis-=x_axis[-1]

    fig, (ax1,ax2,ax3) = plt.subplots(3, 1, sharex=True,figsize=(16,6))
    
    ax1.set_title(f'{recordtime}')
    split=np.hsplit(X[:,-10:],X[:,-10:].shape[1]) 
    ax1.scatter(x_axis,np.concatenate(split).flatten(),color='red',s=1)
    ax1.set_ylabel("X position (mm)")
    ax1.set_ylim(-0.6,0.6)
    ax1.grid()
    ax1.text(0.02,0.05,'Downstream Horizontal',transform=ax1.transAxes,ha='left',va='bottom',fontsize=10)

    split=np.hsplit(Y[:,-10:],Y[:,-10:].shape[1]) 
    ax2.scatter(x_axis,np.concatenate(split).flatten(),color='red',s=1)
    ax2.set_ylabel("Y position (mm)")
    ax2.set_ylim(-0.6,0.6)
    ax2.grid()
    ax2.text(0.02,0.05,'Downstream Vertical',transform=ax2.transAxes,ha='left',va='bottom',fontsize=10)

    split=np.hsplit(charge[:,-10:],charge[:,-10:].shape[1])
    ax3.scatter(x_axis,np.concatenate(split).flatten(),color='blue',s=1)
    ax3.set_xlabel("Turn")
    ax3.set_ylabel("Charge (a.u.)")
    ax3.set_ylim(0,1.2)
    ax3.set_xticks([-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,0])
    ax3.set_yticks([0,0.2,0.4,0.6,0.8,1])
    ax3.grid()
    ax3.text(0.02,0.05,'Downstream Charge',transform=ax3.transAxes,ha='left',va='bottom',fontsize=10)
    plt.xlim(-10,0)
    plt.subplots_adjust(hspace=.1)
    plt.savefig(f'/mnt/SBOR/RFSoC/{recordtime}/LERDV_{recordtime}_plot.png',dpi=100,bbox_inches='tight',pad_inches=0.5)
    plt.close()

    


    print("Plot saved successfully.")

    
def main():
    directory = '/mnt/SBOR/ZCU111/2024c/'  # ディレクトリのパスを指定する
    latest_file, previous_file = find_latest_dat_files(directory)
    
    if latest_file:
        parse_and_plot(previous_file)
    
    else:
        print("No dat files found in the directory.")

if __name__ == "__main__":
    main()
