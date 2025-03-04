/*
**	Command & Conquer Red Alert(tm)
**	Copyright 2025 Electronic Arts Inc.
**
**	This program is free software: you can redistribute it and/or modify
**	it under the terms of the GNU General Public License as published by
**	the Free Software Foundation, either version 3 of the License, or
**	(at your option) any later version.
**
**	This program is distributed in the hope that it will be useful,
**	but WITHOUT ANY WARRANTY; without even the implied warranty of
**	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**	GNU General Public License for more details.
**
**	You should have received a copy of the GNU General Public License
**	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


/***********************************************************************************************
 ***              C O N F I D E N T I A L  ---  W E S T W O O D  S T U D I O S               ***
 ***********************************************************************************************
 *                                                                                             *
 *                 Project Name : Command & Conquer/ WW Library                                *
 *                                                                                             *
 *                    File Name : WINCOMM.H                                                    *
 *                                                                                             *
 *                   Programmer : Steve Tall                                                   *
 *                                                                                             *
 *                   Start Date : 1/10/96                                                      *
 *                                                                                             *
 *                  Last Update : January 10th 1996 [ST]                                       *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Overview:                                                                                   *
 *                                                                                             *
 *   Functions for WinModemClass & WinNullModemClass                                           *
 *                                                                                             *
 *   These classes was created to replace the greenleaf comms functions used in C&C DOS with   *
 *  WIN32 API calls.                                                                           *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 *                                                                                             *
 * Functions:                                                                                  *
 *                                                                                             *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */



//#include "function.h"
#include 	"wincomm.h"
#include	"timer.h"
#include	"keyboard.h"
#include	"misc.h"
#include <io.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <fcntl.h>


/*
** Define this to log modem activity to disk.
*/
//#define LOG_MODEM

/*
** Object represents a serial port
*/
WinModemClass	*SerialPort = NULL;



/***********************************************************************************************
 * WMC::WinModemClass -- WinModemClass constructor                                             *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:14PM ST : Created                                                              *
 *=============================================================================================*/

WinModemClass::WinModemClass(void)
{
	/*
	** Allocate memory for our internal circular serial input buffer
	*/
	SerialBuffer = new unsigned char [SIZE_OF_WINDOWS_SERIAL_BUFFER];

	/*
	** Initialise the serial buffer pointers
	*/
	SerialBufferReadPtr	= 0;
	SerialBufferWritePtr	= 0;

	/*
	** Clear the waiting flags
	*/
	WaitingForSerialCharRead	= FALSE;
	WaitingForSerialCharWrite	= FALSE;

	/*
	** No default abort or echo function
	*/
	AbortFunction = NULL;
	EchoFunction  = NULL;


	/*
	** Clear the running error count
	*/
	FramingErrors=0;
	IOErrors=0;
	BufferOverruns=0;
	InBufferOverflows=0;
	ParityErrors=0;
	OutBufferOverflows=0;

	/*
	** We havnt opened a port yet so...
	*/
	PortHandle = 0;
}



/***********************************************************************************************
 * WMC::~WinModemClass -- destructor for WinModemClass                                         *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:15PM ST : Created                                                              *
 *=============================================================================================*/

WinModemClass::~WinModemClass(void)
{
	/*
	** Close the port
	*/
	if (PortHandle){
		Serial_Port_Close();
	}

	/*
	** Free the serial buffer
	*/
	if (SerialBuffer){
		delete [] SerialBuffer;
	}
}



/***********************************************************************************************
 * Get_Registry_Sub_Key -- search a registry key for a sub-key                                 *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    handle of key to search                                                           *
 *           text to search for                                                                *
 *           true if old key should be closed when new key opened                              *
 *                                                                                             *
 * OUTPUT:   handle to the key we found or 0                                                   *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/12/96 2:11PM ST : Created                                                              *
 *=============================================================================================*/

HKEY Get_Registry_Sub_Key (HKEY base_key, char *search_key, BOOL close)
{

	char		class_string[1024];
	DWORD		string_size = 1024;
	DWORD		num_sub_keys;
	DWORD		longest_sub_key_name;
	DWORD		longest_class_string;
	DWORD		num_value_entries;
	DWORD		longest_value_name_length;
	DWORD		longest_value_data_length;
	DWORD		security_descriptor_length;
	FILETIME	last_write_time;
	HKEY		result_key;
	DWORD		sub_key_buffer_size;

	char		*sub_key_buffer;
	char		*sub_key_class;


	if (RegQueryInfoKey (base_key,
							&class_string[0],
							&string_size,
							NULL,
							&num_sub_keys,
							&longest_sub_key_name,
							&longest_class_string,
							&num_value_entries,
							&longest_value_name_length,
							&longest_value_data_length,
							&security_descriptor_length,
							&last_write_time) != ERROR_SUCCESS) return (0);

	sub_key_buffer_size = longest_sub_key_name+16;
	sub_key_buffer = new char [sub_key_buffer_size];
	sub_key_class	= new char [longest_class_string+1];

	for (int key_num=0 ; key_num<num_sub_keys ; key_num++){

		*sub_key_buffer = 0;
		longest_sub_key_name = sub_key_buffer_size;
		RegEnumKeyEx(base_key,
						key_num,
						sub_key_buffer,
						&longest_sub_key_name,
						NULL,
						sub_key_class,
						&longest_class_string,
						&last_write_time);

		if (!stricmp(search_key, sub_key_buffer)){

			if (RegOpenKeyEx(	base_key,
									sub_key_buffer,
									NULL,
									KEY_READ,
									&result_key) == ERROR_SUCCESS){

				if (close){
					RegCloseKey(base_key);
				}
				delete [] sub_key_buffer;
				delete [] sub_key_class;
				return (result_key);
			}
		}

	}

	if (close){
		RegCloseKey(base_key);
	}
	delete [] sub_key_buffer;
	delete [] sub_key_class;
	return (0);
}



/***********************************************************************************************
 * Get_Modem_Name_From_Registry -- retrieve the name of the installed modem from the registry  *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    buffer to put the name in                                                         *
 *           length of buffer                                                                  *
 *                                                                                             *
 * OUTPUT:   TRUE if modem was found in the registry                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/12/96 2:13PM ST : Created                                                              *
 *=============================================================================================*/
BOOL Get_Modem_Name_From_Registry(char *buffer, int buffer_len)
{
	HKEY	key;
	char	modem_name[256];
	DWORD	modem_name_size = 256;

	key = Get_Registry_Sub_Key (HKEY_LOCAL_MACHINE, "Enum", FALSE);
	if (!key) return (FALSE);

	key = Get_Registry_Sub_Key (key, "Root", TRUE);
	if (!key) return (FALSE);

	key = Get_Registry_Sub_Key (key, "Modem", TRUE);
	if (!key) return (FALSE);

	key = Get_Registry_Sub_Key (key, "0000", TRUE);
	if (!key) return (FALSE);

	if (RegQueryValueEx(key, "FriendlyName", NULL, NULL, (unsigned char*)&modem_name[0], &modem_name_size) != ERROR_SUCCESS){
		RegCloseKey(key);
		return (FALSE);
	}

	RegCloseKey(key);
	memcpy (buffer, modem_name, min(buffer_len, modem_name_size));
	return (TRUE);
}







#ifdef cuts

/***********************************************************************************************
 * WMC::Serial_Port_Open -- opens a com port for asyncronous read/write and gets a handle to it*
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Com port 	- 0=com1, 1=com2 etc.                                                 *
 *           baud rate 	- bits per second                                                     *
 *           parity 		- true or false                                                       *
 *           word length	- 5 to 8 bits                                                         *
 *           stop bits	- 0=1 stop bit, 1=1.5 & 2=2                                           *
 *                                                                                             *
 * OUTPUT:   Handle to port                                                                    *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:17PM ST : Created                                                              *
 *=============================================================================================*/

//VOID FAR PASCAL lineCallbackFunc(DWORD hDevice, DWORD dwMsg,
//    DWORD dwCallbackInstance, DWORD dwParam1, DWORD dwParam2,
//   DWORD dwParam3)

VOID FAR PASCAL lineCallbackFunc(DWORD ,DWORD ,DWORD ,DWORD ,DWORD ,DWORD);

extern HINSTANCE ProgramInstance;

HANDLE	WinModemClass::Serial_Port_Open (int com, int baud, int parity, int wordlen, int stopbits)
{
	HANDLE			com_handle;			//temporary storage for the port handle
	DCB				device_control;	//device control block
	COMMTIMEOUTS	timeouts;			//timeout values
	char				modem_name[256];	//name of modem
	char				device_name[266]={"\\\\.\\"};	//device name to open
	DWORD				config_size = 2048;
	char				config[2048];
	COMMCONFIG		*modem_config = (COMMCONFIG*)&config[0];
	MODEMDEVCAPS	*modem_caps;
	int				temp;
	BOOL				found_modem;

	/*
	** Map for com port values to device names
	*/
	static char com_ids[8][5]={
		"COM1",
		"COM2",
		"COM3",
		"COM4",
		"COM5",
		"COM6",
		"COM7",
		"COM8"
	};


	HLINEAPP 	app_line_handle;
	DWORD			num_devices;

	lineInitialise (&app_line_handle, ProgramInstance, &lineCallbackFunc, NULL, &num_devices);






	found_modem = TRUE;

	if (!Get_Modem_Name_From_Registry(modem_name, 256)){
		strcpy(modem_name, com_ids[com]);
		found_modem = FALSE;
	}

	strcat(device_name, modem_name);


	PortHandle = 0;

	/*
	** Open the com port for asyncronous reads/writes
	*/
	com_handle = CreateFile (device_name, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, NULL);

	if (com_handle == INVALID_HANDLE_VALUE) return (com_handle);

	PortHandle = com_handle;

	/*
	** Set the size of the windows communication buffers
	*/
	SetupComm(com_handle, 2048, 2048);


	/*
	** Create an event object for asyncronous reads
	*/
	ReadOverlap.Internal 		= 0;
	ReadOverlap.InternalHigh	= 0;
	ReadOverlap.Offset			= 0;
	ReadOverlap.OffsetHigh		= 0;
	ReadOverlap.hEvent			= CreateEvent (NULL, TRUE, TRUE, NULL);

	/*
	** Create an event object for asyncronous writes
	*/
	WriteOverlap.Internal 		= 0;
	WriteOverlap.InternalHigh	= 0;
	WriteOverlap.Offset			= 0;
	WriteOverlap.OffsetHigh		= 0;
	WriteOverlap.hEvent			= CreateEvent (NULL, TRUE, TRUE, NULL);

	if (!found_modem){
		/*
		** Get the current state of the com port as a basis for our device control block
		*/
		GetCommState (com_handle , &device_control);

		/*
		** Communications settings
		*/
		device_control.BaudRate = baud;
		device_control.fParity 	= parity;
		device_control.ByteSize = wordlen;
		device_control.StopBits	= stopbits-1;

		/*
		** Misc settings for flow control etc.
		*/
		device_control.fBinary			= TRUE;							// Binary mode data transfer
		device_control.fOutxCtsFlow 	= TRUE;  						// CTS flow control
		device_control.fRtsControl		= RTS_CONTROL_HANDSHAKE;	// RTS flow control
		device_control.fErrorChar		= FALSE;							// Dont put an error char into our input stream
		device_control.fOutxDsrFlow	= FALSE;							// No DSR flow control
		device_control.fDtrControl		= DTR_CONTROL_ENABLE;		// Enable control of DTR line
		device_control.fOutX				= FALSE;							// No XON/XOF flow control
		device_control.fInX				= FALSE;							// No XON/XOF flow control
		device_control.fAbortOnError	= FALSE;							// Device continues to send after an error

		/*
		** Pass the device settings to windows
		*/
		if (SetCommState (com_handle , &device_control) != TRUE){
			Serial_Port_Close();
			return (INVALID_HANDLE_VALUE);
		}
	}else{

		/*
		** If we are talking to a modem device then turn off compression and error correction
		*/
		GetCommConfig(PortHandle ,modem_config, &config_size);

		if (modem_config->dwProviderSubType == PST_MODEM){
			temp = modem_config->dwProviderOffset;
			temp += (int)modem_config;
			modem_caps = (MODEMDEVCAPS*)temp;
			modem_caps->dwModemOptions &= ~(	MDM_COMPRESSION |
														MDM_ERROR_CONTROL |
														MDM_FLOWCONTROL_HARD);
			SetCommConfig(PortHandle, modem_config ,(unsigned)config_size);
		}
	}


	/*
	** Set the device timeouts
	*/
	timeouts.ReadIntervalTimeout 			= 10000;	//10 seconds between incoming packets
	timeouts.ReadTotalTimeoutMultiplier = 0;		//disable total timeouts
	timeouts.ReadTotalTimeoutConstant	= 0;		//disable total timeouts
    timeouts.WriteTotalTimeoutMultiplier= 0;		//disable total timeouts
    timeouts.WriteTotalTimeoutConstant	= 0;		//disable total timeouts

	if (SetCommTimeouts(com_handle, &timeouts) !=TRUE){
		Serial_Port_Close();
		return (INVALID_HANDLE_VALUE);
	}

	return (com_handle);
}
#endif





/***********************************************************************************************
 * WMC::Serial_Port_Open -- opens a com port for asyncronous read/write and gets a handle to it*
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Com port 	- 0=com1, 1=com2 etc.                                                 *
 *           baud rate 	- bits per second                                                     *
 *           parity 		- true or false                                                       *
 *           word length	- 5 to 8 bits                                                         *
 *           stop bits	- 0=1 stop bit, 1=1.5 & 2=2                                           *
 *           flow control- 0 = none, 1 = hardware                                              *
 *                                                                                             *
 * OUTPUT:   Handle to port                                                                    *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:17PM ST : Created                                                              *
 *=============================================================================================*/
HANDLE	WinModemClass::Serial_Port_Open (char *device_name, int baud, int parity, int wordlen, int stopbits, int flowcontrol)
{
	HANDLE			com_handle;			//temporary storage for the port handle
	DCB				device_control;	//device control block
	COMMTIMEOUTS	timeouts;			//timeout values
#if (0)
	/*
	** Map for com port values to device names
	*/
	static char com_ids[8][5]={
		"COM1",
		"COM2",
		"COM3",
		"COM4",
		"COM5",
		"COM6",
		"COM7",
		"COM8"
	};
#endif	//(0)

	int	errorval;
	char	errortxt[128];

	char devname[266]={"\\\\.\\"};	//device name to open
	strcat (devname, device_name);

	PortHandle = 0;

	/*
	** Open the com port for asyncronous reads/writes
	*/
	//com_handle = CreateFile (&com_ids[com][0], GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, NULL);
	com_handle = CreateFile (devname, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, NULL);

	if (com_handle == INVALID_HANDLE_VALUE) return (com_handle);

	PortHandle = com_handle;

	/*
	** Set the size of the windows communication buffers
	*/
	SetupComm(com_handle, SIZE_OF_WINDOWS_SERIAL_BUFFER, SIZE_OF_WINDOWS_SERIAL_BUFFER);

	/*
	** Reset any read or write operation and purge the buffers
	*/
	PurgeComm (PortHandle, PURGE_TXABORT | PURGE_RXABORT | PURGE_TXCLEAR | PURGE_RXCLEAR);

	/*
	** Create an event object for asyncronous reads
	*/
	ReadOverlap.Internal 		= 0;
	ReadOverlap.InternalHigh	= 0;
	ReadOverlap.Offset			= 0;
	ReadOverlap.OffsetHigh		= 0;
	ReadOverlap.hEvent			= CreateEvent (NULL, TRUE, TRUE, NULL);

	/*
	** Create an event object for asyncronous writes
	*/
	WriteOverlap.Internal 		= 0;
	WriteOverlap.InternalHigh	= 0;
	WriteOverlap.Offset			= 0;
	WriteOverlap.OffsetHigh		= 0;
	WriteOverlap.hEvent			= CreateEvent (NULL, TRUE, TRUE, NULL);


	/*
	** Get the current state of the com port as a basis for our device control block
	*/
	if (GetCommState (com_handle , &device_control)){

		/*
		** Communications settings
		*/
		device_control.BaudRate = baud;
		device_control.fParity 	= parity;
		device_control.ByteSize = (char)wordlen;
		device_control.StopBits	= (char)(stopbits-1);

		/*
		** Misc settings for flow control etc.
		*/
		device_control.fBinary			= TRUE;							// Binary mode data transfer
		device_control.fOutxCtsFlow 	= TRUE;  						// CTS flow control
		device_control.fRtsControl		= RTS_CONTROL_HANDSHAKE;	// RTS flow control
		device_control.fErrorChar		= FALSE;							// Dont put an error char into our input stream
		device_control.fOutxDsrFlow	= FALSE;							// No DSR flow control
		device_control.fDtrControl		= DTR_CONTROL_ENABLE;		// Enable control of DTR line
		device_control.fOutX				= FALSE;							// No XON/XOF flow control
		device_control.fInX				= FALSE;							// No XON/XOF flow control
		device_control.fAbortOnError	= FALSE;							// Device continues to send after an error

		/*
		** Disable hardware flow control if required
		*/
		if (!flowcontrol){
			device_control.fOutxCtsFlow 	= FALSE;  					// CTS flow control
			device_control.fRtsControl		= RTS_CONTROL_DISABLE;	// RTS flow control
		}

		/*
		** Pass the device settings to windows
		*/
		if ( !SetCommState (com_handle , &device_control)){
			errorval = GetLastError();
			sprintf (errortxt, "RA95 -- SetCommState returned error code %d.\n", errorval);
			OutputDebugString (errortxt);
			//Serial_Port_Close();
			//return (INVALID_HANDLE_VALUE);
		}
	}else{
		errorval = GetLastError();
		sprintf (errortxt, "RA95 -- GetCommState returned error code %d.\n", errorval);
		OutputDebugString (errortxt);
	}



	/*
	** Set the device timeouts
	*/
	timeouts.ReadIntervalTimeout 			= 1000;	//1 second between incoming bytes will time-out the read
	timeouts.ReadTotalTimeoutMultiplier = 0;		//disable per byte timeouts
	timeouts.ReadTotalTimeoutConstant	= 3000;	//Read operations time out after 3 secs if no data received
    timeouts.WriteTotalTimeoutMultiplier= 500;	//Allow 1/2 ms between each char write
    timeouts.WriteTotalTimeoutConstant	= 1000;	//Write operations time out after 1 sec + 1/2 sec per char if data wasnt sent

	if ( !SetCommTimeouts(com_handle, &timeouts) ){
		errorval = GetLastError();
		sprintf (errortxt, "RA95 -- SetCommTimeouts returned error code %d.\n", errorval);
		OutputDebugString (errortxt);
		//Serial_Port_Close();
		//return (INVALID_HANDLE_VALUE);
	}

	return (com_handle);
}





/***********************************************************************************************
 * WMC::Set_Modem_Dial_Type -- sets dial type to WC_TOUCH_TONE or WC_PULSE                     *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    WC_TOUCH_TONE or WC_PULSE                                                         *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:22PM ST : Created                                                              *
 *=============================================================================================*/

void WinModemClass::Set_Modem_Dial_Type(WinCommDialMethodType method)
{
	DialingMethod = method;
}




/***********************************************************************************************
 * WMC::Get_Modem_Status -- gets the status of the modem control lines                         *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Modem status. Any of the following bits CTS_SET, DSR_SET, RI_SET or CD_SET        *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:24PM ST : Created                                                              *
 *=============================================================================================*/

unsigned WinModemClass::Get_Modem_Status(void)
{
	DWORD		modem_stat = 0;
	unsigned	long return_stat = 0;

	/*
	** Get the modem status
	*/
	GetCommModemStatus(PortHandle, &modem_stat);

	/*
	** Translate the windows status flags to greenleaf flags
	*/
	if (MS_CTS_ON  & modem_stat) return_stat |= CTS_SET;
	if (MS_DSR_ON  & modem_stat) return_stat |= DSR_SET;
	if (MS_RING_ON & modem_stat) return_stat |= RI_SET;
	if (MS_RLSD_ON & modem_stat) return_stat |= CD_SET;

	return (return_stat);

}



/***********************************************************************************************
 * WMC::Set_Serial_DTR -- set the state of the modems DTR control line                         *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    state - true or false                                                             *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:25PM ST : Created                                                              *
 *=============================================================================================*/
void WinModemClass::Set_Serial_DTR(BOOL state)
{
	if (state){
		EscapeCommFunction(PortHandle, SETDTR);
	}else{
		EscapeCommFunction(PortHandle, CLRDTR);
	}
}





/***********************************************************************************************
 * WMC::Serial_Port_Close -- close the port and free the port handle                           *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:26PM ST : Created                                                              *
 *=============================================================================================*/

void WinModemClass::Serial_Port_Close (void)
{
	if (PortHandle){
		CloseHandle(PortHandle);
		PortHandle = 0;
	}
}



/***********************************************************************************************
 * WMC::Read_Serial_Chars -- copys chars from the windows serial buffer to the class buffer    *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   TRUE if any chars read                                                            *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:26PM ST : Created                                                              *
 *=============================================================================================*/

void Smart_Printf( char *format, ... );
BOOL WinModemClass::Read_Serial_Chars (void)
{
	DWORD	bytes_read;				//amount of data read this time
	BOOL	read_result;			//result of ReadFile
	BOOL	overlap_result;		//result of GetOverlappedResult
	DWORD	total_bytes_read=0;	//total amount of data read
	int	bytes_to_read;
	int	i;

	/*
	** Are we were still waiting for the last read operation to finish?
	*/
	if (WaitingForSerialCharRead){

		/*
		** Check the result of the last read operation
		*/
		bytes_read = 0;
		overlap_result = GetOverlappedResult(PortHandle, &ReadOverlap, &bytes_read, FALSE);

		/*
		** If we got a good result from GetOverlappedResult and data was read then move it
		**  to our circular buffer
		*/
		if (overlap_result){
			WaitingForSerialCharRead = FALSE;	//Flag that we are no longer waiting for a read

			if (bytes_read){
				for (i=0 ; i<bytes_read ; i++){
					*(SerialBuffer + SerialBufferWritePtr++) = TempSerialBuffer[i];
					SerialBufferWritePtr &= SIZE_OF_WINDOWS_SERIAL_BUFFER - 1;
				}
				total_bytes_read += bytes_read;
			}
		}else{
			/*
			** No chars were read since last time so just return
			*/
			if (GetLastError() == ERROR_IO_INCOMPLETE){
				return (FALSE);
			}
		}

	}


	/*
	**
	** There is no outstanding read to wait for so try a new read
	**
	*/

	/*
	** Clear the event object
	*/
	ResetEvent(ReadOverlap.hEvent);


	/*
	**
	** Clear any communications errors and get the number of bytes in the in buffer
	**
	*/
	DWORD 	error;
	COMSTAT	status;

	bytes_to_read = 1;

	if (ClearCommError(PortHandle, &error,	&status)){

		InQueue 	= status.cbInQue;
		OutQueue	= status.cbOutQue;

		if (error){
			if (CE_FRAME & error)	FramingErrors++;
			if (CE_IOE & error) 		IOErrors++;
			if (CE_OVERRUN & error) BufferOverruns++;
			if (CE_RXOVER & error)  InBufferOverflows++;
			if (CE_RXPARITY & error)ParityErrors++;
			if (CE_TXFULL & error)  OutBufferOverflows++;
			bytes_to_read = 0;
		}else{
			bytes_to_read = min(status.cbInQue, SIZE_OF_WINDOWS_SERIAL_BUFFER);
		}
	}

	if (!bytes_to_read) bytes_to_read++;


	/*
	**
	** Start reading bytes
	**
	*/

	do{
		/*
		** Try a read operation
		*/
		bytes_read = 0;
		read_result = ReadFile(PortHandle ,TempSerialBuffer ,bytes_to_read ,&bytes_read, &ReadOverlap);

		if (!read_result){

			/*
			** Read failed
			*/
			if (GetLastError() == ERROR_IO_PENDING){

				/*
				** But it threaded in the background OK so flag that we must wait for it to finish
				*/
				WaitingForSerialCharRead = TRUE;
			}

		}else{

			/*
			** Read was successful - copy to our circular buffer and try reading again
			*/
			if (bytes_read){
				for (i=0 ; i<bytes_read ; i++){
					*(SerialBuffer + SerialBufferWritePtr++) = TempSerialBuffer[i];
					SerialBufferWritePtr &= SIZE_OF_WINDOWS_SERIAL_BUFFER - 1;
				}
				total_bytes_read += bytes_read;
			}
		bytes_to_read = 1;
		}

	} while (read_result == TRUE);

	return ((BOOL)total_bytes_read);
}







/***********************************************************************************************
 * WMC::Read_From_Serial_Port -- retrieves chars from the internal class circular buffer which *
 *                               is filled from the windows serial buffer                      *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    buffer to copy to                                                                 *
 *           size of buffer                                                                    *
 *                                                                                             *
 * OUTPUT:   number of chars copied                                                            *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:27PM ST : Created                                                              *
 *=============================================================================================*/

int WinModemClass::Read_From_Serial_Port (unsigned char *dest_ptr, int buffer_len)
{
	int	bytes_read;
	int	bytes_to_copy = 0;
	unsigned char *original_dest = dest_ptr;

	/*
	** Get any outstanding data from the windows serial buffer into our class' circular buffer
	*/
	bytes_read = Read_Serial_Chars();

	if (bytes_read){

		/*
		** Calculate how many bytes should be copied to the user buffer
		*/
		bytes_to_copy = SerialBufferWritePtr - SerialBufferReadPtr;
		if (bytes_to_copy <0 ) bytes_to_copy += SIZE_OF_WINDOWS_SERIAL_BUFFER;
		if (bytes_to_copy>buffer_len) bytes_to_copy = buffer_len;

		/*
		** Loop to copy the data from the internal class buffer to the users buffer
		*/
		for (int i=0 ; i<bytes_to_copy ; i++){

			/*
			** Call the users echo function if required
			*/
			if (EchoFunction && *(SerialBuffer + SerialBufferReadPtr) !=13 ){
				EchoFunction(*(SerialBuffer + SerialBufferReadPtr));
			}

			*dest_ptr++ = *(SerialBuffer + SerialBufferReadPtr++);
			SerialBufferReadPtr &= SIZE_OF_WINDOWS_SERIAL_BUFFER-1;
		}
	}

#ifdef LOG_MODEM

	if (bytes_read){

		char *outstr = new char[bytes_read+1];
		memcpy (outstr, original_dest, bytes_read);
		outstr[bytes_read] = 0;
		OutputDebugString (outstr);

		int	handle;

		handle = open("COMMLOG.TXT",O_WRONLY | O_CREAT | O_APPEND | O_TEXT);

		if (handle != -1){
			write(handle, original_dest, bytes_read);
			close(handle);
		}
	}
#endif	//LOG_MODEM


	return(bytes_to_copy);
}




/***********************************************************************************************
 * WMC::Wait_For_Serial_Write -- waits for output buffer to empty                              *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:29PM ST : Created                                                              *
 *=============================================================================================*/

void WinModemClass::Wait_For_Serial_Write()
{
	DWORD						bytes_written;
	BOOL						overlap_result;
	BOOL 						wait_send;
	CountDownTimerClass	timer;

	if (WaitingForSerialCharWrite){

		timer.Set(60*5);

		/*
		** Wait until the overlapped port write is finished
		*/
		do{
			wait_send = FALSE;
			overlap_result = GetOverlappedResult(PortHandle, &WriteOverlap, &bytes_written, FALSE);

			if (!overlap_result){
				if (GetLastError() == ERROR_IO_INCOMPLETE){
					wait_send = TRUE;
				}
			}

		}while(wait_send && timer.Time());

		WaitingForSerialCharWrite = FALSE;
	}

	ResetEvent(WriteOverlap.hEvent);
}




/***********************************************************************************************
 * WMC::Write_To_Serial_Port -- writes data to the serial port                                 *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    ptr to data                                                                       *
 *           bytes to write                                                                    *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:29PM ST : Created                                                              *
 *=============================================================================================*/

void WinModemClass::Write_To_Serial_Port (unsigned char *buffer, int length)
{
	DWORD	bytes_written;
	BOOL	write_result;


#ifdef LOG_MODEM

	if (length){

		char *outstr = new char[length+1];
		memcpy (outstr, buffer, length);
		outstr[length] = 0;
		OutputDebugString (outstr);

		int	handle;

		handle = open("COMMLOG.TXT",O_WRONLY | O_CREAT | O_APPEND | O_TEXT);

		if (handle != -1){
			write(handle, buffer, length);
			close(handle);
		}
	}
#endif	//LOG_MODEM



	/*
	** Wait for the end of the last write operation
	*/
	Wait_For_Serial_Write();

	/*
	** Write the data to the port
	*/
	write_result = WriteFile (PortHandle, buffer, length, &bytes_written, &WriteOverlap);

	if (!write_result){
		if (GetLastError() == ERROR_IO_PENDING){
			WaitingForSerialCharWrite = TRUE;
		}
	}

}




/***********************************************************************************************
 * WMC::Get_Modem_Result -- gets the result code from the modem after issuing an 'AT' command  *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    delay for result time-out                                                         *
 *           ptr to buffer to receive modem result                                             *
 *           length of buffer                                                                  *
 *                                                                                             *
 * OUTPUT:   un-elapsed delay                                                                  *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:30PM ST : Created                                                              *
 *=============================================================================================*/

extern void CCDebugString (char*);

int WinModemClass::Get_Modem_Result(int delay, char *buffer, int buffer_len)
{

	CountDownTimerClass	timer;
	int						dest_ptr;
	char						*cr_ptr;
	char						*lf_ptr;
	int						copy_bytes;

	//OutputDebugString ("Wincomm - In Get_Modem_Result\n");

	char abuffer [128];
	sprintf (abuffer, "Wincomm - delay = %d, buffer = %p, buffer_len = %d.\n", delay, buffer, buffer_len);
	//OutputDebugString (abuffer);

	//OutputDebugString ("Wincomm - About to clear input buffer.\n");
	memset(buffer, 0 ,buffer_len);
	dest_ptr = 0;

	/*
	** Loop to parse data from the modem and discard any echoed 'AT' commands or spurious LF
	** and CR characters.
	**
	*/

	//OutputDebugString ("Wincomm - Entering do loop.\n");
	do{
		cr_ptr 	= NULL;			//Set the result pointer to NULL
		//OutputDebugString ("Wincomm - About to set timer.\n");
		timer.Set(delay/16);		//Set and start the timer

		/*
		** Keep reading from the serial port until...
		**    1. we time out
		**    2. the user abort by pressing ESC
		**    3. the supplied buffer fills up
		**    4. there is an app switch
		** or 5. we get a CR character from the modem
		*/
		//OutputDebugString ("Wincomm - About to enter inner do loop.\n");
		do{
			if (AbortFunction){// &&
				 //_Kbd->Check()) {

				//OutputDebugString ("Wincomm - About to call abort function.\n");
				int abort = AbortFunction();
				sprintf (abuffer ,"Wincomm - About function returned %d.\n", abort);
				//OutputDebugString (abuffer);
				if (abort != COMMSUCCESS) return (abort);
			}

			/*
			** If we had lost focus then abort
			*/
			if (AllSurfaces.SurfacesRestored){
				//OutputDebugString ("Wincomm - Aborting due to loss of focus.\n");
				return (0);
			}

			//OutputDebugString ("Wincomm - About to call Read_From_Serial_Port.\n");
			dest_ptr += Read_From_Serial_Port((unsigned char*)(buffer + dest_ptr), (int)buffer_len-dest_ptr);
			sprintf (abuffer, "Wincomm - End of inner do loop. Time is %d.\n", timer.Time());
			//OutputDebugString (abuffer);
		} while (timer.Time() &&
					dest_ptr < buffer_len &&
					!strchr (buffer, 13) );

		//OutputDebugString ("Wincomm - Exited inner do loop.\n");


		/*
		** We need to discard this result if it is just an echo of the 'AT' command we sent
		*/
		cr_ptr = strstr(buffer,"AT");
		if (cr_ptr){
			if (*buffer == 'A' && *(buffer+1) == 'T' && strchr(buffer,13)){
				//OutputDebugString ("Wincomm - Discarding command echo.\n");
				cr_ptr = strchr(buffer,13);
			}
		}

		/*
		** If it wasnt an AT echo then strip off any leading CR/LF characters
		*/
		if (!cr_ptr && (*buffer==13 || *buffer==10)){
			cr_ptr = strchr(buffer,13);
			lf_ptr = strchr(buffer,10);
			if (!cr_ptr || (lf_ptr && lf_ptr < cr_ptr)){
				//OutputDebugString ("Wincomm - Stripping CR/LF.\n");
				cr_ptr = strchr(buffer,10);
			}
		}

		/*
		** Copy the good stuff at the end of the buffer over the 'AT' or CR/LF chars
		*/
		if (cr_ptr){
			//OutputDebugString ("Wincomm - Copying over start of buffer.\n");
			while(*cr_ptr == 13 || *cr_ptr == 10){
				cr_ptr++;
			}

			if (cr_ptr != buffer){
				copy_bytes = (int)cr_ptr - (int)buffer;
				memcpy(buffer, cr_ptr, buffer_len - copy_bytes);
				dest_ptr -= copy_bytes;
			}
		}

		//OutputDebugString ("Wincomm - End of outer do loop.\n");
	}while(cr_ptr);


	/*
	** Terminate the string at the first CR character as this is what Greenleaf does
	*/
	if (strchr(buffer, 13)){
		//OutputDebugString ("Truncating result string.\n");
		*(strchr(buffer, 13)) = 0;
	}

	//sprintf (abuffer, "Wincomm - returning remaining delay of %d.\n", timer.Time());
	//OutputDebugString (abuffer);
	return (timer.Time());
}




/***********************************************************************************************
 * WMC::Dial_Modem -- issue an 'ATD' command to the modem                                      *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    string - number to dial                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: Use Set_Modem_Dial_Type to choose pulse or tone dialling                          *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:32PM ST : Created                                                              *
 *=============================================================================================*/
void WinModemClass::Dial_Modem(char *dial_number)
{
	char	dial_string[80];

	/*
	** Create the dial command to send to the modem
	*/
	strcpy (dial_string, "ATD");
	if (DialingMethod == WC_TOUCH_TONE){
		strcat(dial_string, "T");
	}else{
		strcat(dial_string, "P");
	}

	/*
	** Stick a carriage return on the end
	*/
	strcat (dial_string, dial_number);
	strcat (dial_string, "\r");

	/*
	** Write the dial command to the serial port and wait for the write to complete
	*/
	Write_To_Serial_Port ((unsigned char*)dial_string, strlen(dial_string));
	Wait_For_Serial_Write();
}





/***********************************************************************************************
 * WMC::Send_Command_To_Modem -- send an 'AT' command to the modem and await a response        *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    command string                                                                    *
 *           terminator byte (usually "\r")                                                    *
 *           ptr to buffer to receive modem result code                                        *
 *           length of buffer                                                                  *
 *           timeout delay for waiting for result                                              *
 *           number of times to retry the command                                              *
 *                                                                                             *
 * OUTPUT:   result code                                                                       *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:33PM ST : Created                                                              *
 *=============================================================================================*/

int WinModemClass::Send_Command_To_Modem(char *command, char terminator, char *buffer, int buflen, int delay, int retries)
{

	int				times;
	unsigned	char	tmp_string[80];
	char				tmp_buff[80];
	char				term_string[2];
	int				time;

	/*
	** Build the terminator string
	*/
	term_string[0]	= terminator;
	term_string[1]	= 0;

	/*
	** Create the command from the supplied command and terminator
	*/
	strcpy((char*)tmp_string, command);
	strcat((char*)tmp_string, term_string);


	/*
	** Flush out any pending characters from the port
	*/
	unsigned char	nothing_buff[80];
	Read_From_Serial_Port(nothing_buff,80);
	Sleep (100);
	Read_From_Serial_Port(nothing_buff,80);


	for (times = 0 ; times<retries; times++){

		/*
		** Write the command to the serial port
		*/
//Smart_Printf("%s",tmp_string);
		Write_To_Serial_Port (tmp_string, strlen((char*)tmp_string));
		Wait_For_Serial_Write();

		//Delay(120);

		/*
		** Wait for the result of the command from the modem
		*/
		memset(tmp_buff, 0, 80);
		time = Get_Modem_Result(delay, tmp_buff, 80);
//Smart_Printf("%s%s",tmp_buff,"\r");

		/*
		** If it is a pretty standard result then just return
		*/
		if (!strcmp(tmp_buff,"0")) return (MODEM_CMD_0);
		if (strstr(tmp_buff,"OK")) return (MODEM_CMD_OK);
		if (strstr(tmp_buff,"ERROR")) return (MODEM_CMD_ERROR);

		/*
		** If the result was a 3 digit number then copy it to the users buffer and return OK
		*/
		if (strlen(tmp_buff)==3){
			if ( (tmp_buff[0] >= '0' && tmp_buff[0] <='9') &&
				  (tmp_buff[1] >= '0' && tmp_buff[1] <='9') &&
				  (tmp_buff[2] >= '0' && tmp_buff[2] <='9')) {
				strncpy(buffer, tmp_buff, MIN(buflen, 80));
				return (MODEM_CMD_OK);
			}
		}

		/*
		** It was a non-standard(ish) result so copy it to the users buffer
		*/
		strncpy(buffer, tmp_buff, MIN(buflen, 80));

		/*
		** Spurious write for no apparent reason. Well it was there in the DOS version so...
		*/
		Sleep (100);
		Write_To_Serial_Port((unsigned char*)"\r",1);
		Wait_For_Serial_Write();
		Sleep (100);
	}

	return (ASTIMEOUT);
}



/***********************************************************************************************
 * WMC::Set_Echo_Function -- set up the echo function pointer                                  *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    ptr to echo function                                                              *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:35PM ST : Created                                                              *
 *=============================================================================================*/
void WinModemClass::Set_Echo_Function( void ( *func )( char c) )
{
	EchoFunction = func;
}



/***********************************************************************************************
 * WMC::Set_Abort_Function -- set up the abort function pointer                                *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    ptr to abort function                                                             *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    1/10/96 2:35PM ST : Created                                                              *
 *=============================================================================================*/
void WinModemClass::Set_Abort_Function(int (*func)(void))
{
	AbortFunction = func;
}


/***********************************************************************************************
 * WMC::Get_Port_Handle -- returns a handle to the communications port                         *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Com port handle                                                                   *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    5/23/96 1:25PM ST : Created                                                              *
 *=============================================================================================*/
HANDLE	WinModemClass::Get_Port_Handle(void)
{
	return (PortHandle);
}

