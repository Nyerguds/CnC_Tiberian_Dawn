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


#include <windows.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <fcntl.h>
#include <io.h>
#include <stdio.h>


unsigned char thunk_file[1000000];
unsigned char thunk_file_out[100050];


/***********************************************************************************************
 * Search_For_String -- search for a string of chars within a buffer                           *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    string                                                                            *
 *           ptr to buffer to search in                                                        *
 *           length of buffer                                                                  *
 *                                                                                             *
 * OUTPUT:   ptr to string in buffer or NULL if not found                                      *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:42PM ST : Created                                                             *
 *=============================================================================================*/

char *Search_For_String (char *string , char *buffer_ptr , int buffer_length)
{
	int	j;
	int	string_length=strlen(string);

	for (int i=0 ; i<buffer_length-string_length ; i++){

		for (j=0 ; j<string_length ; j++){
			if ( *(string+j) != *(buffer_ptr+i+j)) break;
		}
		if (j==string_length) return buffer_ptr+i;
	}

	return (NULL);

}




int main(int argc, char *argv[])
{
	int	handle;
	char	find_string[]={";************************ START OF THUNK BODIES************************"};
	char	find_other_string[]={"public _IPX_Initialise@4"};

	char	insert_string1[]={"\n\r;\n\r"};
	char	insert_string2[]={";For some reason, inserting these lines makes it assemble correctly\n\r"};
	char	insert_string3[]={";\n\r"};
	char	insert_string4[]={"Externdef   IPX_Initialise:near\n\r"};
	char	insert_string5[]={"IPX_Initialise label near\n\r\n\r"};

	unsigned char *pointer;
	unsigned char *pointer2;
	int	copy_length;
	int	file_length;

	handle = open ("thipx.asm", O_RDONLY | O_BINARY);

	if (handle==-1)return (1);

	file_length = filelength(handle);

	if (read (handle, thunk_file, file_length) != file_length){
		close (handle);
		return (1);
	}

	close (handle);

	pointer = (unsigned char*)Search_For_String(find_string, (char*)thunk_file, file_length);

	if (pointer){

		pointer += strlen(find_string);

		copy_length = (int)( (int)pointer - (int)&thunk_file[0]);

		memcpy (thunk_file_out, thunk_file, copy_length);

		sprintf ((char*)&thunk_file_out[copy_length], "%s%s%s%s%s", 	insert_string1,
																							insert_string2,
																							insert_string3,
																							insert_string4,
																							insert_string5);


		pointer2 = (unsigned char*)Search_For_String(find_other_string, (char*)pointer, file_length);
		if (!pointer2) return (1);
		pointer2 += strlen(find_other_string);

		memcpy (&thunk_file_out [copy_length+ strlen(insert_string1)
														+ strlen(insert_string2)
														+ strlen(insert_string3)
														+ strlen(insert_string4)
														+ strlen(insert_string5)],
					pointer2,
					file_length-((int)pointer2-(int)&thunk_file[0]));


		handle = open ("thipx.asm", O_WRONLY | O_BINARY | O_TRUNC);

		if (handle == -1) return (1);

		write (handle, thunk_file_out, file_length+ strlen(insert_string1)
																+ strlen(insert_string2)
																+ strlen(insert_string3)
																+ strlen(insert_string4)
																+ strlen(insert_string5));

		close (handle);
	}

	return (0);
}


