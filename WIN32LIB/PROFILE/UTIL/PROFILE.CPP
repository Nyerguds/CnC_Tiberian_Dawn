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
 *                 Project Name : Library profiler                                             *
 *                                                                                             *
 *                    File Name : PROFILE.CPP                                                  *
 *                                                                                             *
 *                   Programmer : Steve Tall                                                   *
 *                                                                                             *
 *                   Start Date : 11/17/95                                                     *
 *                                                                                             *
 *                  Last Update : November 20th 1995 [ST]                                      *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 * Overview:                                                                                   *
 *   Uses a map file to match addresses of functions in the sample file with their names       *
 *                                                                                             *
 *                                                                                             *
 *---------------------------------------------------------------------------------------------*
 *                                                                                             *
 * Functions:                                                                                  *
 *  Start_Profiler -- initialises the profiler data and starts gathering data                  *
 *  Stop_Profiler -- stops the timer and writes the profile data to disk                       *
 *                                                                                             *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


#include <string.h>
#include <stdio.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <fcntl.h>
#include <malloc.h>
#include <io.h>
#include <conio.h>

#define bool int
#define true 1
#define false 0
#define NAME_TABLE_SIZE 1000000					//Storage space for function names
#define SAMPLE_START 1								//Offset (in dwords) of sample data in sample file


/*
** Function prototypes
*/
void Print_My_Name(void);
void Print_Usage(void);
int	 Load_File(char *file_name , unsigned *file_ptr , unsigned mode);
bool Extract_Function_Addresses(void);
unsigned Get_Hex (char string[] , int length);
char *Search_For_Char (char character , char buffer_ptr[] , int buffer_length);
char *Search_For_String (char *string , char *buffer_ptr , int buffer_length);
void Map_Profiler_Hits (void);
void Sort_Functions(void);
void Sort_Functions_Again(void);
void Output_Profile(void);

char		*SampleFile;								//Ptr to sample file name
char		*MapFile;									//Ptr to map file name
unsigned	*SampleFileBuffer;						//Ptr to buffer that sample file is loaded in to
char		*MapFileBuffer;							//Ptr to buffer that map file is loaded in to
unsigned	SampleFileLength;							//Length of sample file
unsigned	MapFileLength;								//Length of map file
char		FunctionNames[NAME_TABLE_SIZE];		//Buffer to store function names in
char		*FunctionNamePtr=&FunctionNames[0];	//Ptr to end of last function name in buffer
int			TotalFunctions;							//Total number of functions extracted from map file
int			SampleRate;									//Number of samples/sec that data was collected at
unsigned	EndCodeSegment;							//Length of the sampled programs code segments

/*
** Structure for collating function data
*/
typedef struct tFunction {
	unsigned	FunctionAddress;						//Address of function relative to start of code seg
	char		*FunctionName;							//Ptr to name of function in FunctionNames buffer
	int		Hits;										//Number of times function was 'hit' when sampling
} Function;

Function	FunctionList[10000];						//max 10,000 functions in map file.




/***********************************************************************************************
 * main -- program entry point                                                                 *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    argc , argv                                                                       *
 *                                                                                             *
 * OUTPUT:   0                                                                                 *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:21PM ST : Created                                                             *
 *=============================================================================================*/

int main(int argc, char *argv[])

{
	Print_My_Name();								// print the programs name


	/*
	** If the arguments dont make sense then print the usage
	*/
	if (argc!=3 ||
			!strcmpi(argv[1],"/?") ||
			!strcmpi(argv[1],"/h") ||
			!strcmpi(argv[1],"/help") ||
			!strcmpi(argv[1],"-?") ||
			!strcmpi(argv[1],"-h") ||
			!strcmpi(argv[1],"-help") ||
			!strcmpi(argv[1],"?") ||
			!strcmpi(argv[1],"h") ||
			!strcmpi(argv[1],"help")){
		Print_Usage();
		return(0);
	}

	/*
	** Get the names of the files to load
	*/
	SampleFile=argv[1];
	MapFile=argv[2];

	/*
	** Load the profile sample file
	*/
	SampleFileLength = Load_File (SampleFile , (unsigned*)&SampleFileBuffer , O_BINARY);
	if (!SampleFileLength) return(0);

	/*
	** The sample rate is the 1st dword in the file
	*/
	SampleRate=*SampleFileBuffer;

	/*
	** Load the .map file
	*/
	MapFileLength = Load_File (MapFile , (unsigned*)&MapFileBuffer , O_BINARY);
	if (!MapFileLength){
		free (SampleFileBuffer);
		return(0);
	}

	/*
	** Get the function names from the map file
	*/
	cprintf ("Extracting function data from map file.\n");
	if (!Extract_Function_Addresses()){
		cprintf ("Error parsing .MAP file - aborting\n\n");
		return (0);
	}

	/*
	** Sort the functions into address order to make it easier to map the functions
	*/
	cprintf ("Sorting function list by address");
	Sort_Functions();

	/*
	** Map the addresses in the sample file to the function addresses
	*/
	cprintf ("\nMapping profiler hits to functions");
	Map_Profiler_Hits();

	/*
	** Sort the functions into order of usage for output
	*/
	cprintf ("\nSorting function list by activity");
	Sort_Functions_Again();
	cprintf ("\n\n");

	/*
	** Print the function usage statistics
	*/
	Output_Profile();

	/*
	** Cleanup and out
	*/
	free (SampleFileBuffer);
	free (MapFileBuffer);
	return(0);
}



/***********************************************************************************************
 * Print_My_Name -- print the programs name and version                                        *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:25PM ST : Created                                                             *
 *=============================================================================================*/

void Print_My_Name(void)
{
	cprintf("Westwood profile data analyzer.\n");
	cprintf("V 1.0 - 11/17/95\n");
	cprintf("Programmer - Steve Tall.\n\n");
}


/***********************************************************************************************
 * Print_Usage -- print the instructions                                                       *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:26PM ST : Created                                                              *
 *=============================================================================================*/

void Print_Usage (void)
{
	cprintf("Usage: PROFILE <sample_file> <map_file)\n\n");
}


/***********************************************************************************************
 * File_Error -- display a file error message                                                  *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    name of file error occurred on                                                    *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:26PM ST : Created                                                             *
 *=============================================================================================*/

void File_Error (char *file_name)
{
	cprintf ("Error reading file:%s - aborting\n",file_name);
}


/***********************************************************************************************
 * Memory_Error -- display an out of memory message                                            *
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
 *    11/20/95 5:27PM ST : Created                                                             *
 *=============================================================================================*/

void Memory_Error (void)
{
	cprintf ("Error - insufficient memory - aborting\n");
}


/***********************************************************************************************
 * Load_File -- load an entire file into memory                                                *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    File name                                                                         *
 *           address to load at                                                                *
 *           read mode (text or binary)                                                        *
 *                                                                                             *
 * OUTPUT:   number of bytes read                                                              *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:27PM ST : Created                                                             *
 *=============================================================================================*/

int Load_File(char *file_name , unsigned *load_addr , unsigned mode)
{
	int		handle;
	unsigned file_length;
	void		*buffer;

	handle=open (file_name , O_RDONLY | mode);

	if (handle==-1){
		File_Error(file_name);
		return (false);
	}

	file_length = filelength(handle);

	if (file_length==-1) return (false);

	buffer = malloc (file_length+10);

	if (!buffer){
		Memory_Error();
		return (false);
	}

	if (read (handle , buffer , file_length)!=file_length){
		File_Error(file_name);
		free(buffer);
		return (false);
	}

	close (handle);
	*load_addr = (unsigned)buffer;
	return (file_length);
}






/***********************************************************************************************
 * Map_Profiler_Hits -- map function hits from sample file to functions in map file            *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: Map file functions must be sorted into address order 1st                          *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:28PM ST : Created                                                             *
 *=============================================================================================*/

void Map_Profiler_Hits (void)
{
	unsigned	*samples=(unsigned*)SampleFileBuffer;
	unsigned	function_hit;

	for (int i=SAMPLE_START ; i<SampleFileLength/4 ; i++){

		function_hit=*(samples+i);
		if (1023==(1023 & i)){
			cprintf (".");
		}


		for (int j=TotalFunctions-1 ; j>=0 ; j--){
			if (FunctionList[j].FunctionAddress < function_hit){
				FunctionList[j].Hits++;
				break;
			}
		}
	}

}


/***********************************************************************************************
 * Sort_Functions -- hideous bubble sort of functions into address order                       *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:29PM ST : Created                                                             *
 *=============================================================================================*/

void Sort_Functions (void)
{
	Function	address_swap;

	if (TotalFunctions>1){

		for (int outer=0 ; outer <TotalFunctions ; outer++){

			address_swap.FunctionAddress=0;

			if (127==(127 & outer)){
				cprintf (".");
			}

			for (int inner=0 ; inner < TotalFunctions-1 ; inner++){

				if (FunctionList[inner].FunctionAddress > FunctionList[inner+1].FunctionAddress ){

					memcpy (&address_swap , &FunctionList[inner] , sizeof(Function));
					memcpy (&FunctionList[inner] , &FunctionList[inner+1] , sizeof(Function));
					memcpy (&FunctionList[inner+1] , &address_swap , sizeof(Function));
				}
			}

			if (!address_swap.FunctionAddress) break;
		}
	}
}


/***********************************************************************************************
 * Sort_Functions -- hideous bubble sort of functions into usage order                         *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:29PM ST : Created                                                             *
 *=============================================================================================*/

void Sort_Functions_Again (void)
{
	Function	address_swap;

	if (TotalFunctions>1){

		for (int outer=0 ; outer <TotalFunctions ; outer++){

			address_swap.FunctionAddress=0;

			if (127==(127 & outer)){
				cprintf (".");
			}

			for (int inner=0 ; inner < TotalFunctions-1 ; inner++){

				if (FunctionList[inner].Hits < FunctionList[inner+1].Hits ){

					memcpy (&address_swap , &FunctionList[inner] , sizeof(Function));
					memcpy (&FunctionList[inner] , &FunctionList[inner+1] , sizeof(Function));
					memcpy (&FunctionList[inner+1] , &address_swap , sizeof(Function));
				}
			}

			if (!address_swap.FunctionAddress) break;
		}
	}
}




/***********************************************************************************************
 * Output_Profile -- output the function data to the screen                                    *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:31PM ST : Created                                                             *
 *=============================================================================================*/

void Output_Profile(void)
{
	double			period=(((double)SampleFileLength/(double)4) - (double)SAMPLE_START) / (double)SampleRate;
	double			percentage;

	printf ( "\n  Profile information from %s and %s.\n\n",SampleFile,MapFile);

	printf ( "Samples collected:%d\n" , SampleFileLength/4-SAMPLE_START);
	printf ( "Sample rate      :%d samples per second\n",SampleRate);
	printf ( "Sample period    :%f seconds\n\n\n" , period);

	printf ( "Hits   %%        Function\n");
	printf ( "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");

	for (int i=0 ; i<TotalFunctions ; i++){

		if (FunctionList[i].Hits){

			percentage= ((double)FunctionList[i].Hits*(double)100) / ((double)SampleFileLength/(double)4-(double)SAMPLE_START);

			printf ("%-6d %-3.3f%% %s\n",FunctionList[i].Hits , percentage , FunctionList[i].FunctionName);
		}

	}
}




/***********************************************************************************************
 * Extract_Function_Addresses -- gets the addresses of all global functions from a map file    *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: true if successfully extracted                                                    *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:31PM ST : Created                                                             *
 *=============================================================================================*/

bool Extract_Function_Addresses(void)
{
	char		*map_ptr;
	char		*segment_ptr;
	char		*end_str_ptr;
	unsigned	chars_left=MapFileLength;
	int		function_name_length;
	unsigned	end_of_last_code_segment;
	unsigned	code_segment_start;
	unsigned	code_segment_size;
	char		unknown[]={"Windows API or system code."};

	/*
	** Clear out the list of functions
	*/
	memset (&FunctionNames[0] , 0 , NAME_TABLE_SIZE);

	/*
	** Search for the 'Segments' header in the memory map
	*/
	segment_ptr = Search_For_String ("Segments" , MapFileBuffer , chars_left);
	if (!segment_ptr) return (false);
	chars_left = MapFileLength - ( (unsigned)segment_ptr - (unsigned)MapFileBuffer );
	segment_ptr = Search_For_String ("+-----" , segment_ptr , chars_left);
	segment_ptr +=2;
	chars_left = MapFileLength - ( (unsigned)segment_ptr - (unsigned)MapFileBuffer );

	/*
	** Get the length of the segment section by searching for the start of the next section
	*/
	end_str_ptr = Search_For_String ("+-----" , segment_ptr , chars_left);
	if (end_str_ptr){
		chars_left = end_str_ptr - segment_ptr;
	} else {
		return (false);
	}

	EndCodeSegment = 0;

	/*
	** Find the end of the last code segment
	*/
	do {
		/*
		** Search for a code segment identifier
		*/
		chars_left = end_str_ptr - segment_ptr;
		segment_ptr = Search_For_String ("CODE" , segment_ptr , chars_left);
		if (!segment_ptr) break;		//No more code segments so break

		/*
		**  Search for the segment address which should always be 0001
		*/
		chars_left = end_str_ptr - segment_ptr;
		segment_ptr = Search_For_String ("0001:" , segment_ptr , chars_left);
		if (!segment_ptr) return (false);	//Couldnt find the segment address - must be a problem so abort

		/*
		** Get the start address and length of the segment
		*/
		code_segment_start = Get_Hex(segment_ptr+5,8);
		code_segment_size = Get_Hex(segment_ptr+16,8);

		/*
		** If this segment ends higher in memory than the previous highest then
		** we have a new last segment
		*/
		if (code_segment_start+code_segment_size > EndCodeSegment){
			EndCodeSegment = code_segment_start+code_segment_size;
		}

		chars_left = end_str_ptr - segment_ptr;
		segment_ptr = Search_For_Char ( 13 , segment_ptr , chars_left );
		chars_left = end_str_ptr - segment_ptr;

	} while (chars_left > 0);



	chars_left=MapFileLength;
	/*
	** Search for the 'Memory Map' segment of the map file
	*/
	map_ptr = Search_For_String ("Memory Map" , MapFileBuffer , chars_left);
	if (!map_ptr){
		return (false);
	}
	chars_left = MapFileLength - ( (unsigned)map_ptr - (unsigned)MapFileBuffer );

	/*
	** Get the length of the memory map segment by searching for the start of the next segment
	*/
	end_str_ptr = Search_For_String ("+-----" , map_ptr , chars_left);
	if (end_str_ptr){
		MapFileLength = ((unsigned)MapFileBuffer + MapFileLength) - (unsigned)end_str_ptr;
	}
	chars_left = MapFileLength - ( (unsigned)map_ptr - (unsigned)MapFileBuffer );

	/*
	** Reset the total number of functions found
	*/
	TotalFunctions = 0;

	/*
	**
	** Find each occurrence of 0001: as all the functions we want are in the 1st segment
	**
	*/
	do {
		/*
		**  Find '0001:'
		*/
		map_ptr = Search_For_String ("0001:" , map_ptr , chars_left);
		if (!map_ptr){
			break;
		}
		chars_left = MapFileLength - ( (unsigned)map_ptr - (unsigned)MapFileBuffer );

		/*
		** Skip the '0001:' portion of the address and get the hext offset of the function
		*/
		map_ptr+=5;
		FunctionList[TotalFunctions].FunctionAddress=Get_Hex(map_ptr,8);

		/*
		** Skip to the function name and get its length by searching for the end of the line
		*/
		map_ptr+=10;
		chars_left = MapFileLength - ( (unsigned)map_ptr - (unsigned)MapFileBuffer );
		end_str_ptr = Search_For_Char (13 , map_ptr , chars_left);
		if (!end_str_ptr){
			break;
		}
		function_name_length = (unsigned)end_str_ptr - (unsigned)map_ptr;

		/*
		** Copy the function name into the name list and keep a pointer to it
		*/
		memcpy (FunctionNamePtr , map_ptr , function_name_length);
		FunctionList[TotalFunctions].FunctionName = FunctionNamePtr;
		FunctionNamePtr += function_name_length+1;		//Leave an extra 0 on the end as a terminator
		FunctionList[TotalFunctions].Hits = 0;				//We dont yet know how many times we hit it
		TotalFunctions++;

	} while (1);


	/*
	** Add in a dummy function at the highest address to represent unknown code hits
	*/
	FunctionList[TotalFunctions].FunctionAddress = EndCodeSegment;
	memcpy (FunctionNamePtr , &unknown , sizeof (unknown));
	FunctionList[TotalFunctions].FunctionName = FunctionNamePtr;
	FunctionNamePtr += sizeof (unknown);
	FunctionList[TotalFunctions].Hits = 0;
	TotalFunctions++;

	return (true);
}




/***********************************************************************************************
 * Get_Hex -- nasty function to convert an ascii hex number to an unsigned int                 *
 *            I'm sure there must be a lovely 'c' way of doing this but I dont know what it is *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    ptr to ascii hex string , number of digits in string                              *
 *                                                                                             *
 * OUTPUT:   value of hex string                                                               *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:39PM ST : Created                                                             *
 *=============================================================================================*/

unsigned Get_Hex (char string[] , int length)
{
	unsigned	hex_val=0;
	int		multiplier=1;
	char		hex_char;

	for (int i=0 ; i<length ; i++){
		hex_char=string[length-1-i];

		switch (hex_char){
			case  '0':
				hex_char=0;
				break;

			case  '1':
				hex_char=1;
				break;

			case  '2':
				hex_char=2;
				break;

			case  '3':
				hex_char=3;
				break;

			case  '4':
				hex_char=4;
				break;

			case  '5':
				hex_char=5;
				break;

			case  '6':
				hex_char=6;
				break;

			case  '7':
				hex_char=7;
				break;

			case  '8':
				hex_char=8;
				break;

			case  '9':
				hex_char=9;
				break;

			case  'A':
				hex_char=10;
				break;

			case  'B':
				hex_char=11;
				break;

			case  'C':
				hex_char=12;
				break;

			case  'D':
				hex_char=13;
				break;

			case  'E':
				hex_char=14;
				break;

			case  'F':
				hex_char=15;
				break;

			case  'a':
				hex_char=10;
				break;

			case  'b':
				hex_char=11;
				break;

			case  'c':
				hex_char=12;
				break;

			case  'd':
				hex_char=13;
				break;

			case  'e':
				hex_char=14;
				break;

			case  'f':
				hex_char=15;
				break;

		}

		hex_val += hex_char * multiplier;
		multiplier = multiplier<<4;
	}
	return (hex_val);
}



/***********************************************************************************************
 * Search_For_Char -- search through ascii data for a particular character                     *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    character                                                                         *
 *           ptr to buffer                                                                     *
 *           length of buffer                                                                  *
 *                                                                                             *
 * OUTPUT:   ptr to char in buffer or NULL if not found                                        *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    11/20/95 5:41PM ST : Created                                                             *
 *=============================================================================================*/

char *Search_For_Char (char character , char buffer_ptr[] , int buffer_length)
{

	for ( unsigned i=0 ; i<buffer_length ; i++){

		if (buffer_ptr[i]==character){
			return ((char*) (unsigned)buffer_ptr+i);
		}
	}
	return (NULL);
}



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





