import profile
# pip install pythonbenchmark
from pythonbenchmark import compare, measure
import fflyusb_wrapper
import time

@measure
def CachedReadAndResetSecuritySwitchFlags(x10i):
    x10i.CachedReadAndResetSecuritySwitchFlags()

def main():

    x10i = fflyusb_wrapper.PyFireFlyUSB()
    if not x10i.init(0):
        print("Unable to initialise x10i, check you have a PIC fitted")
    else:
        if not x10i.UnlockHardware():
            print("Unable to unlock the hardware!")
            if not x10i.VerifyHardwareUnlockLibrary():
                print("unlockio_64.o does not match fitted PIC")
        else:
            print('Product version information:')

            if x10i.GetProductVersion():
                print('Product version            : ' + x10i.ProductVersion)
            if x10i.GetDllVersion():
                print('API library version        : ' + x10i.DllVersion)
            if x10i.Get8051Version():
                print('8051 software version      : ' + x10i._8051Version)
            if x10i.GetPICVersion():
                print('PIC software version       : ' + x10i.PICVersion)
            if x10i.GetPICSerialNumber():
                print('PIC serial number          : ' + x10i.PICSerialNumber)
            if x10i.GetFittedBoard():
                print('Fitted board               : ' + str(x10i.FittedBoard))
            if x10i.GetBoardSpeed():
                print('Board speed                : ' + str(x10i.BoardSpeed))
            if x10i.StartSecuritySwitchRead():
                if x10i.CachedReadAndResetSecuritySwitchFlags():
                    print('open                       : ' + str(x10i.security_closedSwitches))
                    print('closed                     : ' + str(x10i.security_openSwitches))

            # time 10x cached calls.
            time.sleep(1)
            x10i.StartSecuritySwitchRead()
            for x in range(0, 9):
                CachedReadAndResetSecuritySwitchFlags(x10i)
                time.sleep(0.5)


    # x10i.RelockHardware()                # causes PIC information to become unavailable?

if __name__ == '__main__':
    #profile.run('main()')
    main()
