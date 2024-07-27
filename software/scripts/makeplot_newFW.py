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
    xPosFault = []
    yPosFault = []
    qBunchFault = []
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
    
            # Check if AMP Live waveform
            elif header.channel == 24:
                fpData = data[hdrOffset:].view(np.float32)
                fpDataLen = len(fpData)
                xPosFault.append(   fpData[0:(fpDataLen*3)+0:3] ) 
                yPosFault.append(   fpData[1:(fpDataLen*3)+1:3] )
                qBunchFault.append( fpData[2:(fpDataLen*3)+2:3] )
            
            # Else undefined stream index
            else:
                print( f'UNDEFINED DATA STREAM[{header.channel}]!!!')
    return ampFault, recordtime

def parse_and_plot(filename,x1,x2):
    ampFault, recordtime=datfile(filename)
    eventnum=0
    print(f'filename : {filename}')
    print(f'Recorded time : {recordtime[0]}')
    recordtime=recordtime[0].replace(' ', '_').replace(':', '-')
    
    def bunchindex(threshold,waveform):
        bunch_index=[]
        for i in range(2560):
            if max(ampFault[0][eventnum][i:i+50])<500:
                start=i+50
                break
        #print(start)
        for i in range(5120):
            if waveform[start+i]>threshold:
                bunch_index.append(start+i)

        if len(bunch_index)==0:
            print("data is not invalid")
            return bunch_index

        if len(bunch_index)<300:
            print('Nbunch is too small')
            return []

        print(f'Nbunch={len(bunch_index)}')
        return np.array(bunch_index)

    bunch_index=bunchindex(500,ampFault[0][eventnum])
    if len(bunch_index)==0:
        print("end process")
        return 0

    os.makedirs(f'/mnt/SBOR/RFSoC/{recordtime}', exist_ok=True)
    
    UV=[]
    DV=[]
    charge_U=[]
    charge_D=[]
    for j in bunch_index:
        certain_bunch_UV=[]
        certain_bunch_DV=[]
        certain_bunch_charge_U=[]
        certain_bunch_charge_D=[]
        for i in range(102):
            tbt_0=ampFault[0][eventnum][j+5120*i]
            tbt_1=ampFault[1][eventnum][j+5120*i]
            tbt_2=ampFault[2][eventnum][j+5120*i]
            tbt_3=ampFault[3][eventnum][j+5120*i]
            certain_bunch_UV.append(tbt_3/tbt_2*(-16.58)/5)
            certain_bunch_DV.append(tbt_1/tbt_0*(-16.58)/5)
            certain_bunch_charge_U.append(tbt_2)
            certain_bunch_charge_D.append(tbt_0)
        UV.append(np.array(certain_bunch_UV))
        DV.append(np.array(certain_bunch_DV))
        charge_U.append(np.array(certain_bunch_charge_U))
        charge_D.append(np.array(certain_bunch_charge_D))
    UV=np.array(UV)
    DV=np.array(DV)
    charge_U=np.array(charge_U)
    charge_D=np.array(charge_D)

    mean=np.mean(UV[:,0:10],axis=1)
    UV=UV-mean[:,np.newaxis]
    mean=np.mean(DV[:,0:10],axis=1)
    DV=DV-mean[:,np.newaxis]
    charge_mean=np.mean(charge_U[:,0:10],axis=1)
    charge_U=charge_U/charge_mean[:,np.newaxis]
    charge_mean=np.mean(charge_D[:,0:10],axis=1)
    charge_D=charge_D/charge_mean[:,np.newaxis]
            
    #make x axis
    bunch_index_10=[]
    for i in range(10):
        bunch_index_10.append(bunch_index-bunch_index[0]+5120*i)
    x_axis=np.concatenate(bunch_index_10)/5120

    #x_axis_0=[]
    #print(DV.shape)
    #for i in range(101):
    #    x_axis_0.append(bunch_index-bunch_index[0]+5120*i)
    #x_axis=np.concatenate(x_axis_0)/0.509
    
    fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True,figsize=(16,6))
    split=np.hsplit(UV[:,-10:],UV[:,-10:].shape[1])
    ax1.set_title(f'{recordtime}')
    ax1.scatter(x_axis,np.concatenate(split),color='tomato',s=6)
    ax1.set_ylabel("Y position (mm)")
    ax1.set_ylim(-0.4,0.4)
    ax1.grid()
    ax1.text(0.02,0.05,'Upstream Vertical',transform=ax1.transAxes,ha='left',va='bottom',fontsize=14)

    split=np.hsplit(charge_U[:,-10:],charge_U[:,-10:].shape[1])
    ax2.scatter(x_axis,np.concatenate(split).reshape(len(x_axis)),color='royalblue',s=6)
    ax2.set_xlabel("Turn")
    ax2.set_ylabel("Charge")
    ax2.set_ylim(0,1.2)
    ax2.grid()
    
    ax2.set_xticks([0,1,2,3,4,5,6,7,8,9,10],['-10','-9','-8','-7','-6','-5','-4','-3','-2','-1','0'])
    ax2.set_yticks([0,0.2,0.4,0.6,0.8,1])
    ax2.set_xlim(x1,x2)
    ax2.text(0.02,0.05,'Upstream Charge',transform=ax2.transAxes,ha='left',va='bottom',fontsize=14)
    ax2.set_xlabel("Turn")
    plt.subplots_adjust(hspace=.1)
    plt.savefig(f'/mnt/SBOR/RFSoC/{recordtime}/LERUV_{recordtime}_plot.png',dpi=200,bbox_inches="tight",pad_inches=0.5)
    plt.close()
    
    
    fig2, (ax1, ax2) = plt.subplots(2, 1, sharex=True,figsize=(18,6))
    split=np.hsplit(DV[:,-10:],DV[:,-10:].shape[1])
    #split=np.hsplit(DV,DV.shape[1])
    ax1.set_title(f'{recordtime}')
    ax1.scatter(x_axis,np.concatenate(split),color='red',s=6)
    ax1.set_ylabel("Y position (mm)")
    ax1.set_ylim(-0.4,0.4)
    ax1.grid()
    ax1.text(0.02,0.05,'Downstream Vertical',transform=ax1.transAxes,ha='left',va='bottom',fontsize=14)

    split=np.hsplit(charge_D[:,-10:],charge_D[:,-10:].shape[1])
    #split=np.hsplit(charge_D,charge_D.shape[1])
    ax2.scatter(x_axis,np.concatenate(split).reshape(len(x_axis)),color='blue',s=6)
    ax2.set_xlabel("Turn")
    ax2.set_ylabel("Charge (a.u.)")
    ax2.set_ylim(0,1.2)
    ax2.grid()
    
    ax2.set_xticks([0,1,2,3,4,5,6,7,8,9,10],['-10','-9','-8','-7','-6','-5','-4','-3','-2','-1','0'])
    ax2.set_yticks([0,0.2,0.4,0.6,0.8,1])
    ax2.set_xlim(x1,x2)
    ax2.text(0.02,0.05,'Downstream Charge',transform=ax2.transAxes,ha='left',va='bottom',fontsize=14)
    plt.subplots_adjust(hspace=.1)
    plt.savefig(f'/mnt/SBOR/RFSoC/{recordtime}/LERDV_{recordtime}_plot.png',dpi=200,bbox_inches="tight",pad_inches=0.5)
    plt.close()

    outputfile=[]
    for i in range(4):
        outputfile.append(ampFault[i][0])
    outputfile=np.array(outputfile)
    outputfile.tofile(f'/mnt/SBOR/RFSoC/{recordtime}/LERFuji_{recordtime}.dat')


    print("Plot saved successfully.")

    
def main():
    directory = '/mnt/SBOR/ZCU111/'  # ディレクトリのパスを指定する
    latest_file, previous_file = find_latest_dat_files(directory)
    
    if latest_file:
        parse_and_plot(previous_file,0,10)
    
    else:
        print("No dat files found in the directory.")

if __name__ == "__main__":
    main()
