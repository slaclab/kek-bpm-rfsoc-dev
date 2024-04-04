#!/usr/bin/env python3

import os
import glob
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
                
                formatted_time = time.strftime('%Y-%m-%d_%H-%M-%S', timestamp)
                #print( f'CH={header.channel}: Event Timestamp in human-readable format: {formatted_time}' )
                if header.channel==24:
                    recordtime.append(formatted_time)
            
            else:
                hdrOffset = 0
                print( 'No timestamp header detected' )
                return 0,0
            
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

def parse_and_plot(dat_file):
    ampFault, recordtime=datfile(dat_file)
    if recordtime==0:
        return
    
    print(f'Selected time : {recordtime[0]}')
    
    def bunchindex(threshold,waveform):
        start=12800
        firstbunch=0
        for i in range(1,8*5120):
            if waveform[start+i-1]<waveform[start+i] and waveform[start+i]>waveform[start+i+1]:
                if waveform[start+i]>threshold:
                    firstbunch=start+i
                    break
        if firstbunch==0:
            print("invalid data")
            return firstbunch, 0
    
        bunch_candidate=waveform[firstbunch:firstbunch+5120*8:8]
        bunch_index=np.where(bunch_candidate>threshold)[0]
    
        return firstbunch, bunch_index

    firstbunch, bunch_index=bunchindex(1000,ampFault[0][0])
    if firstbunch==0:
        print("end process")
        return

    #os.makedirs(f'/home/nomaru/work/auto_BOR/plot/{recordtime[0]}', exist_ok=True)
    os.makedirs(f'/mnt/SBOR/RFSoC/{recordtime[0]}', exist_ok=True)
    print(f'Downstream Num of bunch : {len(bunch_index)}')
    print(f'Downstream First bunch index : {firstbunch}')
    start=12800
    y_pos=[]
    charge=[]
    for j in bunch_index:
        certain_bunch=[]
        certain_bunch_charge=[]
        for i in range(12):
            sum=ampFault[0][0][firstbunch+j*8+5120*8*i]
            delta=ampFault[1][0][firstbunch+j*8+5120*8*i]
            yposition=delta/sum*16.58/5+1.6
            certain_bunch.append(yposition)
            certain_bunch_charge.append(sum)
        y_pos.append(np.array(certain_bunch))
        charge.append(np.array(certain_bunch_charge))
    y_pos=np.array(y_pos)
    charge=np.array(charge)

    aspectratio=y_pos.shape[1]/y_pos.shape[0]

    mean=np.mean(y_pos[:,0:3],axis=1)
    y_pos=y_pos-mean[:,np.newaxis]        
    
    fig=plt.figure(figsize=(20,20))
    plt.rcParams["font.size"]=16
    ax1=fig.add_subplot(2,2,1)
    ax2=fig.add_subplot(2,2,2)
    ax3=fig.add_subplot(2,2,3)
    ax4=fig.add_subplot(2,2,4)

    im=ax1.imshow(y_pos,aspect=aspectratio*1.08,cmap='viridis',interpolation='none',extent=(0.5,12.5,y_pos.shape[0],0)
                  ,vmin=-1*0.25,vmax=0.25
                  )

    plt.colorbar(im,label='Y position (mm)',shrink=0.88)
    ax1.set_xlabel("Turn")
    ax1.set_ylabel("Bunch ID")
    ax1.set_xticks([1,2,3,4,5,6,7,8,9,10,11,12])
    
    y_pos_diff=[]
    for i in range(y_pos.shape[0]):
        y_pos_diff.append(y_pos[i][1:]-y_pos[i][:-1])
        
    y_pos_diff=np.array(y_pos_diff)
    
    im2=ax2.imshow(y_pos_diff,aspect=aspectratio,cmap='coolwarm',interpolation='none',extent=(1.5,12.5,y_pos_diff.shape[0],0),vmin=-1*0.25,vmax=0.25)
    plt.colorbar(im2,label='Change in Y position from previous turn (mm)',shrink=0.88)
    ax2.set_xlabel("Turn")
    ax2.set_ylabel("Bunch ID")
    ax2.set_xticks([2,3,4,5,6,7,8,9,10,11,12])

    charge_mean=np.mean(charge[:,0:3],axis=1)
    charge=charge/charge_mean[:,np.newaxis]
    
    im3=ax3.imshow(charge,aspect=aspectratio*1.08,cmap='plasma',interpolation='none',extent=(0.5,12.5,charge.shape[0],0)
                   #,vmin=-1*posrange,vmax=posrange
                   )
    
    plt.colorbar(im3,label='Charge',shrink=0.88)
    ax3.set_xlabel("Turn")
    ax3.set_ylabel("Bunch ID")
    ax3.set_xticks([1,2,3,4,5,6,7,8,9,10,11,12])
    
    charge_diff=[]
    for i in range(charge.shape[0]):
        charge_diff.append(charge[i][1:]-charge[i][:-1])
        
    charge_diff=np.array(charge_diff)
    
    im4=ax4.imshow(charge_diff,aspect=aspectratio,cmap='coolwarm',interpolation='none',extent=(1.5,12.5,charge_diff.shape[0],0)
                   ,vmin=-1,vmax=1
                  )
    plt.colorbar(im4,label='Change in charge from previous turn',shrink=0.88)
    ax4.set_xlabel("Turn")
    ax4.set_ylabel("Bunch ID")
    ax4.set_xticks([2,3,4,5,6,7,8,9,10,11,12])
    #plt.savefig(f'/home/nomaru/work/auto_BOR/plot/{recordtime[0]}/LERDV_{recordtime[0]}_heatmap.png',dpi=200,bbox_inches="tight",pad_inches=0.5)
    #plt.savefig(f'/mnt/SBOR/RFSoC/{recordtime[0]}/LERDV_{recordtime[0]}_heatmap.png',dpi=200,bbox_inches="tight",pad_inches=0.5)
    plt.close()

    #make x axis
    bunch_index_12=[]
    for i in range(12):
        bunch_index_12.append(bunch_index+5120*i)

    x_axis=np.concatenate(bunch_index_12)/5120+1
        

    fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True,figsize=(22,8))
    split=np.hsplit(y_pos,y_pos.shape[1])
    ax1.set_title(f'{recordtime[0]}')
    ax1.scatter(x_axis,np.concatenate(split),color='red',s=6)
    ax1.set_ylabel("Y position (mm)")
    ax1.set_ylim(-0.4,0.4)
    ax1.grid()
    ax1.text(0.03,0.05,'Downstream Vertical',transform=ax1.transAxes,ha='left',va='bottom',fontsize=20)

    split=np.hsplit(charge,charge.shape[1])
    ax2.scatter(x_axis,np.concatenate(split).reshape(len(x_axis)),color='blue',s=6)
    ax2.set_xlabel("Turn")
    ax2.set_ylabel("Charge")
    ax2.set_ylim(0,1.2)
    ax2.grid()
    ax2.set_xticks([1,2,3,4,5,6,7,8,9,10,11,12,13],['1','2','3','4','5','6','7','8','9','10','11','12','abort'])
    ax2.set_yticks([0,0.2,0.4,0.6,0.8,1])
    ax2.set_xlim(4,13)
    ax2.text(0.03,0.05,'Downstream Charge',transform=ax2.transAxes,ha='left',va='bottom',fontsize=20)

    plt.subplots_adjust(hspace=.1)
    #plt.savefig(f'/home/nomaru/work/auto_BOR/plot/{recordtime[0]}/{recordtime[0]}_position_charge.png',dpi=200,bbox_inches="tight",pad_inches=0.5)
    plt.savefig(f'/mnt/SBOR/RFSoC/{recordtime[0]}/LERDV_{recordtime[0]}_plot.png',dpi=200,bbox_inches="tight",pad_inches=0.5)
    plt.close()

    #########################################################

    firstbunch, bunch_index=bunchindex(1700,ampFault[2][0])
    if firstbunch==0:
        print("end process")
        return

    print(f'Upstream Num of bunch : {len(bunch_index)}')
    print(f'Upstream First bunch index : {firstbunch}')
    start=12800
    y_pos=[]
    charge=[]
    for j in bunch_index:
        certain_bunch=[]
        certain_bunch_charge=[]
        for i in range(12):
            sum=ampFault[2][0][firstbunch+j*8+5120*8*i]
            delta=ampFault[3][0][firstbunch+j*8+5120*8*i]
            yposition=delta/sum*16.58/5
            certain_bunch.append(yposition)
            certain_bunch_charge.append(sum)
        y_pos.append(np.array(certain_bunch))
        charge.append(np.array(certain_bunch_charge))
    y_pos=np.array(y_pos)
    charge=np.array(charge)

    aspectratio=y_pos.shape[1]/y_pos.shape[0]

    mean=np.mean(y_pos[:,0:3],axis=1)
    y_pos=y_pos-mean[:,np.newaxis]        
    
    fig=plt.figure(figsize=(20,20))
    plt.rcParams["font.size"]=16
    ax1=fig.add_subplot(2,2,1)
    ax2=fig.add_subplot(2,2,2)
    ax3=fig.add_subplot(2,2,3)
    ax4=fig.add_subplot(2,2,4)

    im=ax1.imshow(y_pos,aspect=aspectratio*1.08,cmap='viridis',interpolation='none',extent=(0.5,12.5,y_pos.shape[0],0)
                  ,vmin=-1*0.25,vmax=0.25
                  )

    plt.colorbar(im,label='Y position (mm)',shrink=0.88)
    ax1.set_xlabel("Turn")
    ax1.set_ylabel("Bunch ID")
    ax1.set_xticks([1,2,3,4,5,6,7,8,9,10,11,12])
    
    y_pos_diff=[]
    for i in range(y_pos.shape[0]):
        y_pos_diff.append(y_pos[i][1:]-y_pos[i][:-1])
        
    y_pos_diff=np.array(y_pos_diff)
    
    im2=ax2.imshow(y_pos_diff,aspect=aspectratio,cmap='coolwarm',interpolation='none',extent=(1.5,12.5,y_pos_diff.shape[0],0),vmin=-1*0.25,vmax=0.25)
    plt.colorbar(im2,label='Change in Y position from previous turn (mm)',shrink=0.88)
    ax2.set_xlabel("Turn")
    ax2.set_ylabel("Bunch ID")
    ax2.set_xticks([2,3,4,5,6,7,8,9,10,11,12])

    charge_mean=np.mean(charge[:,0:3],axis=1)
    charge=charge/charge_mean[:,np.newaxis]
    
    im3=ax3.imshow(charge,aspect=aspectratio*1.08,cmap='plasma',interpolation='none',extent=(0.5,12.5,charge.shape[0],0)
                   #,vmin=-1*posrange,vmax=posrange
                   )
    
    plt.colorbar(im3,label='Charge',shrink=0.88)
    ax3.set_xlabel("Turn")
    ax3.set_ylabel("Bunch ID")
    ax3.set_xticks([1,2,3,4,5,6,7,8,9,10,11,12])
    
    charge_diff=[]
    for i in range(charge.shape[0]):
        charge_diff.append(charge[i][1:]-charge[i][:-1])
        
    charge_diff=np.array(charge_diff)
    
    im4=ax4.imshow(charge_diff,aspect=aspectratio,cmap='coolwarm',interpolation='none',extent=(1.5,12.5,charge_diff.shape[0],0)
                   ,vmin=-1,vmax=1
                  )
    plt.colorbar(im4,label='Change in charge from previous turn',shrink=0.88)
    ax4.set_xlabel("Turn")
    ax4.set_ylabel("Bunch ID")
    ax4.set_xticks([2,3,4,5,6,7,8,9,10,11,12])
    #plt.savefig(f'/home/nomaru/work/auto_BOR/plot/{recordtime[0]}/LERUV_{recordtime[0]}_heatmap.png',dpi=200,bbox_inches="tight",pad_inches=0.5)
    #plt.savefig(f'/mnt/SBOR/RFSoC/{recordtime[0]}/LERUV_{recordtime[0]}_heatmap.png',dpi=200,bbox_inches="tight",pad_inches=0.5)
    plt.close()

    #make x axis
    bunch_index_12=[]
    for i in range(12):
        bunch_index_12.append(bunch_index+5120*i)

    x_axis=np.concatenate(bunch_index_12)/5120+1
        

    fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True,figsize=(22,8))
    split=np.hsplit(y_pos,y_pos.shape[1])
    ax1.set_title(f'{recordtime[0]}')
    ax1.scatter(x_axis,np.concatenate(split),color='tomato',s=6)
    ax1.set_ylabel("Y position (mm)")
    ax1.set_ylim(-0.4,0.4)
    ax1.grid()
    ax1.text(0.03,0.05,'Upstream Vertical',transform=ax1.transAxes,ha='left',va='bottom',fontsize=20)

    split=np.hsplit(charge,charge.shape[1])
    ax2.scatter(x_axis,np.concatenate(split).reshape(len(x_axis)),color='royalblue',s=6)
    ax2.set_xlabel("Turn")
    ax2.set_ylabel("Charge")
    ax2.set_ylim(0,1.2)
    ax2.grid()
    ax2.set_xticks([1,2,3,4,5,6,7,8,9,10,11,12,13],['1','2','3','4','5','6','7','8','9','10','11','12','abort'])
    ax2.set_yticks([0,0.2,0.4,0.6,0.8,1])
    ax2.set_xlim(4,13)
    ax2.text(0.03,0.05,'Upstream Charge',transform=ax2.transAxes,ha='left',va='bottom',fontsize=20)

    plt.subplots_adjust(hspace=.1)
    #plt.savefig(f'/home/nomaru/work/auto_BOR/plot/{recordtime[0]}/{recordtime[0]}_position_charge.png',dpi=200,bbox_inches="tight",pad_inches=0.5)
    plt.savefig(f'/mnt/SBOR/RFSoC/{recordtime[0]}/LERUV_{recordtime[0]}_plot.png',dpi=200,bbox_inches="tight",pad_inches=0.5)
    plt.close()
    
    print("Plot saved successfully.")
    print(f'Abort datetime:{recordtime[0]}')

    
def main():
    directory = '/home/nomaru/projects/kek-bpm-rfsoc-dev/software/datfile/'  # ディレクトリのパスを指定する
    latest_file, previous_file = find_latest_dat_files(directory)
    
    if latest_file:
        parse_and_plot(previous_file)
    
    else:
        print("No dat files found in the directory.")

if __name__ == "__main__":
    main()


