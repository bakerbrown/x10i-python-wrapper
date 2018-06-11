#https://stackoverflow.com/questions/38393393/wrapping-a-c-dll-using-cython-all-strings-are-empty
#build with
#python3 setup.py build_ext --inplace

## distutils: library_dirs = /usr/src/xlinedevkit_x64/lib/
## distutils: runtime_library_dirs = /usr/lib/


# distutils: include_dirs = /usr/src/xlinedevkit_x64/include/
# distutils: libraries = fflyusb_x64
# distutils: extra_objects = /usr/src/xlinedevkit_x64/lib/unlockio_x64.o
# distutils: extra_link_args = -pthread
# distutils: extra_compile_args = -Wall -O2 -DX10_LINUX_BUILD -fPIC
# distutils: language = c++

from libcpp.string cimport string
from libcpp cimport bool

cdef extern from *:

    cdef extern from "fflyusb.h" namespace "":

        ctypedef enum usbOutputId:
            USB_OP_0,
            USB_OP_1,
            USB_OP_2,
            USB_OP_3,
            USB_OP_AUX

        ctypedef struct usbOutput:
            unsigned char    byOut[4]   # Outputs [0..3]
            unsigned char    byAux      # Aux Output

        cdef cppclass FireFlyUSB:

            FireFlyUSB()

            bool init(int PortNumber)     						        # Initialises USB
            bool close()

            bool GetFittedBoard( unsigned char* fittedBoard )			# Unidentified, X10 or X10i connected
            bool GetBoardSpeed( unsigned char* boardSpeed )			    # UNKNOWN_SPEED, USB_1_1_FULL_SPEED or USB_2_0_HIGH_SPEED

            bool GetProductVersion( unsigned char* ProductVersion )
            bool GetDllVersion( unsigned char* DllVersion )
            bool Get8051Version( unsigned char* _8051Version ) 			# Memory pipe
            bool GetPICVersion( unsigned char* PICVersion )			    # Security pipe
            bool GetPICSerialNumber( unsigned char* PICSerialNumber )	# Security pipe

            bool SetPICSerialNumber( unsigned char* serialNumberPIC )	# Security pipe
            bool GetDallasSerialNumber( unsigned char* serialNumberDallas, unsigned char* crcValid ) # Security pipe

            bool RelockHardware()

            bool SetOnPeriodOutputs( usbOutput onPeriods )
            bool SetOffPeriodOutputs( usbOutput offPeriods )
            bool ConfigureReelsEx( char numberOfReels, int halfStepsPerTurn, char stepsPerSymbol )
            bool SetOutputBrightness( char brightness )

            bool SetClock( unsigned int time )
            bool GetClock( unsigned int* time )

            bool NextSecuritySwitchRead( unsigned long* time, unsigned char* switches )
            bool StartSecuritySwitchRead()
            bool ClearSecuritySwitches()
            bool ReadAndResetSecuritySwitchFlags( unsigned char* closedSwitches, unsigned char* openSwitches )
            bool CachedReadAndResetSecuritySwitchFlags( unsigned char* closedSwitches, unsigned char* openSwitches )

cdef class PyFireFlyUSB:

    # Hold a C++ instance which we are wrapping
    cdef FireFlyUSB *thisptr

    # Available in Python-space:
    cdef public str ProductVersion
    cdef public str DllVersion
    cdef public str _8051Version
    cdef public str PICVersion
    cdef public str PICSerialNumber
    cdef public int FittedBoard
    cdef public int BoardSpeed
    cdef public str serialNumberDallas
    cdef public int crcValid

    cdef public int security_time
    cdef public char security_switches
    cdef public char security_closedSwitches
    cdef public char security_openSwitches

    def __cinit__(self):
        self.thisptr = new FireFlyUSB()

    def __dealloc__(self):
        del self.thisptr

# System Functions.

    #
    def init(self, int BoardNumber):
        return self.thisptr.init(BoardNumber)

    #
    def close(self):
        return self.thisptr.close()

    # I an attempt to make things more pythonic we use the wrapper to do
    # the housekeeping, i.e. changing the returned bytearray into a Pyhon string.

    #
    def GetFittedBoard(self):
        temp = bytearray(4)
        success = self.thisptr.GetFittedBoard(temp)
        self.FittedBoard = temp[0]
        del temp
        return success

    #
    def GetBoardSpeed(self):
        temp = bytearray(4)
        success = self.thisptr.GetBoardSpeed(temp)
        self.BoardSpeed = temp[0]
        del temp
        return success

    #
    def GetProductVersion(self):
        temp = bytearray(20)
        success = self.thisptr.GetProductVersion(temp)
        self.ProductVersion = temp.decode('utf-8').strip('\x00')
        del temp
        return success # {'ProductVersion', self.ProductVersion}

    #
    def GetDllVersion(self):
        temp = bytearray(20)
        success = self.thisptr.GetDllVersion(temp)
        self.DllVersion = temp.decode('utf-8').strip('\x00')
        del temp
        return success # {'DllVersion', self.DllVersion}

    #
    def Get8051Version(self):
        temp = bytearray(20)
        success = self.thisptr.Get8051Version(temp)
        self._8051Version = temp.decode('utf-8').strip('\x00')
        del temp
        return success # {'8051Version', self._8051Version}

    def GetLastError(self):
        pass

# IO Pipe functions.

    def SetOnPeriodOutputs(self, onPeriods):
        cdef usbOutput temp
        temp.byOut[0] = onPeriods[0]
        temp.byOut[1] = onPeriods[1]
        temp.byOut[2] = onPeriods[2]
        temp.byOut[3] = onPeriods[3]
        temp.byAux = onPeriods[4]
        return self.thisptr.SetOnPeriodOutputs(temp)

    def SetOffPeriodOutputs(self, offPeriods):
        cdef usbOutput temp
        temp.byOut[0] = offPeriods[0]
        temp.byOut[1] = offPeriods[1]
        temp.byOut[2] = offPeriods[2]
        temp.byOut[3] = offPeriods[3]
        temp.byAux = offPeriods[4]
        return self.thisptr.SetOffPeriodOutputs(temp)

    def ConfigureReelsEx(self, numberOfReels, halfStepsPerTurn, stepsPerSymbol):
        return self.thisptr.ConfigureReelsEx(numberOfReels, halfStepsPerTurn, stepsPerSymbol)

    def SetOutputBrightness(self, brightness):
        return self.thisptr.SetOutputBrightness(brightness)

# Security pipe functions.

    #
    def GetPICVersion(self):
        temp = bytearray(10)
        success = self.thisptr.GetPICVersion(temp)
        # Error in API with data after \0 so let fix it.
        self.PICVersion = "".join(chr(x) for x in bytearray(temp)).split('\0', 1)[0]
        return success # {'PICVersion', self.PICVersion}

    #
    def GetPICSerialNumber(self):
        temp = bytearray(9)
        success = self.thisptr.GetPICSerialNumber(temp)
        self.PICSerialNumber = "".join(chr(x) for x in bytearray(temp))
        return success # {'PICSerialNumber', self.PICSerialNumber}

    def SetPICSerialNumber(self):
        pass

    def GetDallasSerialNumber(self):
        dallas = bytearray(8)
        crc = bytearray(4)
        success = self.thisptr.GetDallasSerialNumber(dallas, crc)
        print('family code = {}'.format(dallas[0]))
        print('Unique serial = {}.{}.{}.{}.{}.{}'.format(dallas[1],dallas[2],dallas[3],dallas[4],dallas[5],dallas[6]))
        print('CRC = {}'.format(dallas[7]))
        print('crc = {}'.format(crc))

# Security clock

    def SetClock(self, time):
        return self.thisptr.SetClock(time)

    def GetClock(self):
        pass
        #return self.thisptr.GetClock(self.security_time)

    def RelockHardware(self):
        return self.thisptr.RelockHardware()


# Security switches

    def NextSecuritySwitchRead(self):
        cdef unsigned long time
        cdef unsigned char switches
        success = self.thisptr.NextSecuritySwitchRead( &time, &switches )
        self.security_time = time
        self.security_switches = switches
        return success

    def StartSecuritySwitchRead(self):
        return self.thisptr.StartSecuritySwitchRead()

    def ClearSecuritySwitches(self):
        return self.thisptr.ClearSecuritySwitches()

    def ReadAndResetSecuritySwitchFlags(self):
        cdef unsigned char openSwitches
        cdef unsigned char closedSwitches
        success = self.thisptr.ReadAndResetSecuritySwitchFlags( &closedSwitches, &openSwitches )
        self.security_closedSwitches = closedSwitches
        self.security_openSwitches = openSwitches
        return success

    def CachedReadAndResetSecuritySwitchFlags(self):
        cdef unsigned char openSwitches
        cdef unsigned char closedSwitches
        success = self.thisptr.CachedReadAndResetSecuritySwitchFlags( &closedSwitches, &openSwitches )
        self.security_closedSwitches = closedSwitches
        self.security_openSwitches = openSwitches
        return success

# Security battery

    def ReadAndResetBatteryFailFlag(self):
        pass

    def ReadAndResetRTCFailure(self):
        pass

    def EnableRandomNumberGenerator(self):
        pass

# random number generator

    def GetRandomNumber(self):
        pass

    def EnableRandomNumberGenerator(self):
        pass

    def DisableRandomNumberGenerator(self):
        pass



    def ReadAndResetRTCFailure(self):
        pass

    def ReadClockAtBatteryFailure(self):
        pass

    #
    def UnlockHardware(self):
        return UnlockX10(self.thisptr)

    #
    def UnlockHardwareRecheck(self):
        return UnlockX10Recheck(self.thisptr)

    #
    def VerifyHardwareUnlockLibrary(self):
        return VerifyX10UnlockLibrary(self.thisptr)



cdef extern from "unlockio.h":

    bool UnlockX10( FireFlyUSB * FireFly )
    bool UnlockX10Recheck( FireFlyUSB * FireFly )
    bool VerifyX10UnlockLibrary( FireFlyUSB * FireFly )
