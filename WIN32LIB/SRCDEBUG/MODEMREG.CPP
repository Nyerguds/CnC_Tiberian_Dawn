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
 *                    File Name : MODEMREG.CPP                                                 *
 *                                                                                             *
 *                   Programmer : Steve Tall                                                   *
 *                                                                                             *
 *                   Start Date : 10/18/96                                                     *
 *                                                                                             *
 *                  Last Update : October 18th 1996 [ST]                                       *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Overview:                                                                                   *
 *                                                                                             *
 *   Functions for obtaining modem infommation from the Win95 registry                         *
 *                                                                                             *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 *                                                                                             *
 * Functions:                                                                                  *
 *                                                                                             *
 * Search_Registry_Key -- Search a registry key and all its subkeys for a given value          *
 * MREC::ModemRegistryEntryClass -- Constructor for ModemRegistryEntryClass                    *
 * MREC::~ModemRegistryEntryClass -- Destructor.Free all the memory we allocated for modem info*
 *                                                                                             *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */





#include "modemreg.h"
#include <stdio.h>


extern HKEY Get_Registry_Sub_Key (HKEY base_key, char *search_key, BOOL close);




/***********************************************************************************************
 * Search_Registry_Key -- Search a registry key and all its subkeys for a given value          *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    handle to key to search in                                                        *
 *           name of key to search for                                                         *
 *           value expected in key                                                             *
 *                                                                                             *
 * OUTPUT:   Handle to key containing value. Null if not found.                                *
 *                                                                                             *
 * WARNINGS: This function reenters itself.                                                    *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    10/18/96 4:01AM ST : Created                                                             *
 *=============================================================================================*/
HKEY Search_Registry_Key (HKEY key_in, char *value_name, char *search_string)
{

	int 	top_key_index = 0;				// Index of topmost key
	int 	retval;								// Result of registry api calls
	HKEY	next_key;							// handle of next key examine
	HKEY	next_search;						// handle of next key to search


	char				*subkey_name = new char [256];			// Area to contain result of key enumeration
	unsigned long	subkey_name_length = 256;					// Length of enumeration result area
	FILETIME			filetime;										// Time key was last touched. Not used.
	unsigned long	value_type;										// Type of data that is contained in a key.
	unsigned char	*key_value = new unsigned char [256];	// Area to return key values into
	unsigned long	key_value_length = 256;						// Length of key value area

	/*
	** Scan through and enumerate all subkeys of this key. Exit the loop when there are
	** no more sub keys to enumerate.
	*/
	do {
		subkey_name_length = 256;			// Has to be set each time through the loop

		/*
		** Get the next key
		*/
		retval = RegEnumKeyEx (key_in, top_key_index++, subkey_name, &subkey_name_length, NULL, NULL, NULL, &filetime);

		if ( retval == ERROR_SUCCESS ){

			/*
			** Get a handle to this key so we can search it.
			*/
			next_key = Get_Registry_Sub_Key (key_in, subkey_name, FALSE);

			if (next_key){

				key_value_length = 256;		// Has to be set each time through the loop

				if ( RegQueryValueEx (next_key, value_name, NULL, &value_type, key_value, &key_value_length) == ERROR_SUCCESS){

					/*
					** If this value is type string then do a compare with the value we are looking for
					*/
					if (value_type == REG_SZ && !strcmp ((char*)key_value, search_string)){
						/*
						** This is our man. Delete our workspace and return the key handle
						*/
						delete [] subkey_name;
						delete [] key_value;
						return (next_key);
					}
				}

				/*
				** We didnt find our search value so search this key for more sub keys by reentering
				** this function with the handle of the subkey.
				*/
				next_search = Search_Registry_Key (next_key, value_name, search_string);
				RegCloseKey (next_key);

				/*
				** If the value was found in a subkey then just return with the key handle.
				*/
				if (next_search){
					delete [] subkey_name;
					delete [] key_value;
					return (next_search);
				}
			}

		}
	} while (retval == ERROR_SUCCESS);

	/*
	** Clean up and exit.
	*/
	delete [] subkey_name;
	delete [] key_value;

	return (0);
}



/***********************************************************************************************
 * MREC::ModemRegistryEntryClass -- Constructor for ModemRegistryEntryClass                    *
 *                                                                                             *
 *  This function does all the work in the class. All the registry searching is done here      *
 *                                                                                             *
 * INPUT:    Modem number                                                                      *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    10/18/96 4:12AM ST : Created                                                             *
 *=============================================================================================*/
ModemRegistryEntryClass::ModemRegistryEntryClass (int modem_number)
{
	HKEY				key;
	unsigned char	return_buf[256];
	DWORD				retbuf_size = sizeof(return_buf);

	int				pnp = 0;					//Not a plug n pray modem

	/*
	** Initialise all the info we expect from the registry to NULL.
	** Any entries we cant find will just stay NULL.
	*/
	ModemName = NULL;
	ModemDeviceName = NULL;
	ErrorCorrectionEnable = NULL;
	ErrorCorrectionDisable = NULL;
	CompressionEnable = NULL;
	CompressionDisable = NULL;
	HardwareFlowControl = NULL;
	NoFlowControl = NULL;


	/*
	** Modem info is stored under
	** HKEY_LOCAL_MACHINE / System / CurrentControlSet / Services / Class / Modem / nnnn
	** where nnnn is a four digit modem number.
	*/

	key = Get_Registry_Sub_Key (HKEY_LOCAL_MACHINE, "System", FALSE);
	if (!key) return;

	key = Get_Registry_Sub_Key (key, "CurrentControlSet", TRUE);
	if (!key) return;

	key = Get_Registry_Sub_Key (key, "Services", TRUE);
	if (!key) return;

	key = Get_Registry_Sub_Key (key, "Class", TRUE);
	if (!key) return;

	key = Get_Registry_Sub_Key (key, "Modem", TRUE);
	if (!key) return;

	char which_modem[5];
	sprintf (which_modem, "%04d", modem_number);

	/*
	** Get a handle to the modem key if it exists. Then extract the info we need.
	*/
	key = Get_Registry_Sub_Key (key, which_modem, TRUE);
	if (!key) return;


	/*
	** Get the name of the modem. This is what will be displayed in the modem list presented
	** to the user.
	*/
	if (RegQueryValueEx(key, "Model", NULL, NULL, return_buf, &retbuf_size) != ERROR_SUCCESS){
		RegCloseKey (key);
		return;
	}
	ModemName = new char [retbuf_size];
	memcpy (ModemName, return_buf, retbuf_size);

	/*
	** Find out what COM port the modem is attached to. If this info isnt here, then its a
	** Plug n Pray modem. Set the flag so we know to do the pnp search later.
	*/
	retbuf_size = sizeof (return_buf);
	if (RegQueryValueEx(key, "AttachedTo", NULL, NULL, return_buf, &retbuf_size) != ERROR_SUCCESS){
		/*
		** Must be a plug n pray modem. Set the flag. We will look for the port later.
		*/
		pnp = 1;
		ModemDeviceName = new char [strlen (ModemName)+1];
		strcpy (ModemDeviceName, ModemName);
	}else{
		ModemDeviceName = new char [retbuf_size];
		memcpy (ModemDeviceName, return_buf, retbuf_size);
	}


	/*
	** The list of modem 'AT' commands is stored in the 'Settings'  key.
	*/
	key = Get_Registry_Sub_Key (key, "Settings", TRUE);
	if (!key) return;


	/*
	** Extract the control strings for error control.
	*/
	retbuf_size = sizeof (return_buf);
	if (RegQueryValueEx(key, "ErrorControl_On", NULL, NULL, return_buf, &retbuf_size) == ERROR_SUCCESS){
		ErrorCorrectionEnable = new char [retbuf_size];
		memcpy (ErrorCorrectionEnable, return_buf, retbuf_size);
	}

	retbuf_size = sizeof (return_buf);
	if (RegQueryValueEx(key, "ErrorControl_Off", NULL, NULL, return_buf, &retbuf_size) == ERROR_SUCCESS){
		ErrorCorrectionDisable = new char [retbuf_size];
		memcpy (ErrorCorrectionDisable, return_buf, retbuf_size);
	}

	/*
	** Extract the control strings for data compression.
	*/
	retbuf_size = sizeof (return_buf);
	if (RegQueryValueEx(key, "Compression_On", NULL, NULL, return_buf, &retbuf_size) == ERROR_SUCCESS){
		CompressionEnable = new char [retbuf_size];
		memcpy (CompressionEnable, return_buf, retbuf_size);
	}

	retbuf_size = sizeof (return_buf);
	if (RegQueryValueEx(key, "Compression_Off", NULL, NULL, return_buf, &retbuf_size) == ERROR_SUCCESS){
		CompressionDisable = new char [retbuf_size];
		memcpy (CompressionDisable, return_buf, retbuf_size);
	}

	/*
	** Extract the control strings for hardware flow control.
	*/
	retbuf_size = sizeof (return_buf);
	if (RegQueryValueEx(key, "FlowControl_Hard", NULL, NULL, return_buf, &retbuf_size) == ERROR_SUCCESS){
		HardwareFlowControl = new char [retbuf_size];
		memcpy (HardwareFlowControl, return_buf, retbuf_size);
	}

	/*
	** Extract the control strings for no flow control.
	*/
	retbuf_size = sizeof (return_buf);
	if (RegQueryValueEx(key, "FlowControl_Off", NULL, NULL, return_buf, &retbuf_size) == ERROR_SUCCESS){
		NoFlowControl = new char [retbuf_size];
		memcpy (NoFlowControl, return_buf, retbuf_size);
	}



	RegCloseKey (key);



	/*
	** If this is a plug n pray modem then we need to search for the COM port it is
	** attached to.
	*/
	if (pnp){

		/*
		** The driver name in the HKEY_LOCAL_MACHINE / Enum section will be Modem\nnnn where nnnn
	  	** is a four digit modem number.
		*/
		char search_string [256] = {"Modem\\"};
		strcat (search_string, which_modem);

		/*
		** Search through all the registry entries under HKEY_LOCAL_MACHINE / Enum
		*/
		key = Get_Registry_Sub_Key (HKEY_LOCAL_MACHINE, "Enum", FALSE);
		if (!key) return;

		HKEY newkey = Search_Registry_Key ( key, "Driver", search_string );

		if (newkey){
			retbuf_size = sizeof (return_buf);

			/*
			** Extract the PORTNAME value. This is the name of the port to use to communicate
			** with the modem.
			*/
			retbuf_size = sizeof (return_buf);
			if (RegQueryValueEx(newkey, "PORTNAME", NULL, NULL, return_buf, &retbuf_size) == ERROR_SUCCESS){

				if (ModemDeviceName) delete [] ModemDeviceName;

				ModemDeviceName = new char [retbuf_size];
				memcpy (ModemDeviceName, return_buf, retbuf_size);
			}
		}
		RegCloseKey (key);
	}

}








/***********************************************************************************************
 * MREC::~ModemRegistryEntryClass -- Destructor.Free all the memory we allocated for modem info*
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
 *    10/18/96 11:39AM ST : Created                                                              *
 *=============================================================================================*/
ModemRegistryEntryClass::~ModemRegistryEntryClass (void)
{
	if (ModemName) delete [] ModemName;
	if (ModemDeviceName) delete [] ModemDeviceName;

	if (ErrorCorrectionEnable) delete [] ErrorCorrectionEnable;
	if (ErrorCorrectionDisable) delete [] ErrorCorrectionDisable;

	if (CompressionEnable) delete [] CompressionEnable;
	if (CompressionDisable) delete [] CompressionDisable;

	if (HardwareFlowControl) delete [] HardwareFlowControl;
	if (NoFlowControl) delete [] NoFlowControl;
}





