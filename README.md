# Eliko Quadra MATLAB software

MATLAB code for the [Eliko Quadra](https://eliko.tech/quadra-impedance-spectroscopy/) Impedance Spectroscopy system. Read data into Matlab structures, write protocols to table files. Example how to use data with [EIDORS](http://eidors3d.sourceforge.net/)

## Installation

Add the `src` folder to matlab path

## Usage

### Read data file

Read data files output from the Eliko Quadra MUX GUI v1.12

```matlab
Data=quadra.readdata('example.txt');
```

### Write table file

Custom measurement protocols can be then uploaded to `EEPROM` or `FRAM`. 

```matlab
%write single line of adjacent protocol
quadra.writetable('example.csv',[1 2 3 4])
```
