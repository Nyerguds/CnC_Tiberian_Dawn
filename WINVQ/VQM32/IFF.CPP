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

/****************************************************************************
*
*         C O N F I D E N T I A L --- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     iff.c
*
* DESCRIPTION
*     IFF manager. (32-Bit protected mode)
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*      
* DATE
*     January 26, 1995
*
*----------------------------------------------------------------------------
*
* PUBLIC
*     OpenIFF          - Open an IFF for reading or writting.
*     CloseIFF         - Close an IFF.
*     ReadForm         - Read the IFF FORM, size and type of the file.
*     WriteForm        - Write IFF form ID, size and type fields.
*     ReadChunkHeader  - Read the IFF chunk identification header.
*     WriteChunkHeader - Write an IFF chunk identification header.
*     WriteChunk       - Write an IFF chunk with data from a buffer.
*     WriteChunkBytes  - Write data from a buffer to the IFF stream.
*     SkipChunkBytes   - Skip bytes in a chunk.
*     FindChunk        - Scan for a specific chunk name.
*     IDtoStr          - Convert a longword identifier to a NULL-terminated
*                        string.
*     CurrentFilePos   - Get the current file position.
*
****************************************************************************/

#include <stdio.h>
#include <malloc.h>
#include <io.h>
#include <fcntl.h>
#include <sys\stat.h>
#include <mem.h>
#include "iff.h"


/****************************************************************************
*
* NAME
*     OpenIFF - Open an IFF for reading or writting.
*
* SYNOPSIS
*     IFFHandle = OpenIFF(Name, Mode)
*
*     IFFHandle *OpenIFF(char *, long);
*
* FUNCTION
*     Opens an IFF for a new read or write.  The direction of the I/O is
*     given by the value of Mode, which can be either IFF_READ or IFF_WRITE.
*
* INPUTS
*     Name - Pointer to name of file to open.
*     Mode - IFF_READ or IFF_WRITE.
*
* RESULT
*     IFFHandle - Pointer to IFFHandle structure or NULL if error.
*
****************************************************************************/

IFFHandle *OpenIFF(char *name, long mode)
{
	IFFHandle *iff;

	/* Allocate IFFHandle structure. */
	if ((iff = (IFFHandle *)malloc(sizeof(IFFHandle))) != NULL) {

		/* Initialize handle.*/
		memset(iff, 0, sizeof(IFFHandle));
		iff->flags = mode;

		switch (mode) {
			case IFFF_READ:
				iff->fh = open(name, O_RDONLY|O_BINARY);
				break;

			case IFFF_WRITE:
				iff->fh = open(name, (O_CREAT|O_TRUNC|O_WRONLY|O_BINARY),
						(S_IREAD|S_IWRITE));

				printf("\r");
				break;

			case (IFFF_READ|IFFF_WRITE):
				iff->fh = open(name, (O_RDWR|O_BINARY), (S_IREAD|S_IWRITE));
				break;

			default:
				iff->fh = -1;
				break;
		}

		/* If something went wrong we must free up any resources
		 * that we have opened.
		 */
		if (iff->fh == -1) {
			free(iff);
			iff = NULL;
		}
	}

	return (iff);
}


/****************************************************************************
*
* NAME
*     CloseIFF - Close an IFF.
*
* SYNOPSIS
*     CloseIFF(IFFHandle)
*
*     void CloseIFF(IFFHandle *);
*
* FUNCTION
*     Completes an IFF read or write operation.
*
* INPUTS
*     IFFHandle - Pointer to IFFHandle structure.
*
* RESULT
*     NONE
*
****************************************************************************/

void CloseIFF(IFFHandle *iff)
{
	long length;

	/* Write the length of the FORM */
	if ((iff->flags & IFFF_WRITE) && ((iff->form.size == 0)
			|| (iff->scan > iff->form.size))) {

		lseek(iff->fh, 4, SEEK_SET);
		length = REVERSE_LONG(iff->scan);
		write(iff->fh, &length, 4);
	}

	close(iff->fh);
	free(iff);
}


/****************************************************************************
*
* NAME
*     ReadForm - Read the IFF FORM, size and type of the file.
*
* SYNOPSIS
*     Error = ReadForm(IFFHandle, FormHeader)
*
*     long ReadForm(IFFHandle *, FormHeader *);
*
* FUNCTION
*     Read in the IFF form, size, type information. If the FormHeader
*     structure pointer is NULL then the FORM will be read into the
*     IFFHandles form structure.
*
* INPUTS
*     IFFHandle  - Pointer to IFFHandle structure.
*     FormHeader - Pointer to FormHeader structure.
*
* RESULT
*     Error - 0 if successful or IFFERR_??? error code.
*
****************************************************************************/

long ReadForm(IFFHandle *iff, FormHeader *form)
{
	FormHeader *ptr;
 	long       error;

	/* Read the FORM into the IFFHandle or the provided FormHeader. */
	if (form == NULL) {
		ptr = &iff->form;
	} else {
		ptr = form;
	}

	/* Read in IFF FORM from the file stream.. */
	if ((error = read(iff->fh, ptr, 12)) == 12) {
		ptr->size = REVERSE_LONG(ptr->size);
		iff->scan = 4;
		error = 0;
	} else {
		if (error == -1)
			error = IFFERR_READ;
		else if (error == 0)
			error = IFFERR_EOF;
	}

	return (error);
}


/****************************************************************************
*
* NAME
*     WriteForm - Write IFF form ID, size and type fields.
*
* SYNOPSIS
*     Error = WriteForm(IFFHandle)
*
*     long WriteForm(IFFHandle, FormHeader *);
*
* FUNCTION
*     Write out the IFF form, size, type information. If the size field
*     is zero then the IFF form size will be calculated and written by
*     the CloseIFF() function. If the FormHeader structure pointer is NULL
*     the the form from the IFFHandle will be written.
*
* INPUTS
*     IFFHandle  - Pointer to IFFHandle structure.
*     FormHeader - Pointer to FormHeader structure.
*
* RESULT
*     Error - 0 if successful or IFFERR_??? error code.
*
****************************************************************************/

long WriteForm(IFFHandle *iff, FormHeader *form)
{
	FormHeader *ptr;
	long       error = 0;

	/* Use the FORM from the IFFHandle or the provided FormHeader. */
	if (form == NULL) {
		ptr = &iff->form;
	} else {
		ptr = form;
	}

	/* Write the IFF form to the file stream. */
	if (iff->flags & IFFF_WRITE) {
		ptr->size = REVERSE_LONG(ptr->size);

		if (write(iff->fh, ptr, 12) == 12) {
			iff->scan = 4;
		} else {
			error = IFFERR_WRITE;
		}
	} else {
		error = IFFERR_WRITE;
	}

	return (error);
}


/****************************************************************************
*
* NAME
*     ReadChunkHeader - Read the IFF chunk identification header.
*
* SYNOPSIS
*     Error = ReadChunkHeader(IFFHandle)
*
*     long ReadChunkHeader(IFFHandle *);
*
* FUNCTION
*     Read the IFF identification header from the files data stream.
*
* INPUTS
*     IFFHandle - Pointer to IFFHandle structure.
*
* RESULT
*     Error - 0 if successful or IFFERR_??? error code.
*
****************************************************************************/

long ReadChunkHeader(IFFHandle *iff)
{
	long error = 0;

	/* Skip any part of the previous chunk that hasn't been processed. */
	if ((iff->cn.size != 0) && (iff->cn.scan < PADSIZE(iff->cn.size))) {
		error = lseek(iff->fh, (PADSIZE(iff->cn.size) - iff->cn.scan), SEEK_CUR);

		if (error == -1) {
			error = IFFERR_READ;
		} else {
			error = 0;
		}
	}

	/* Read in the next chunk header context. */
	if (!error) {
		if ((error = read(iff->fh, &iff->cn, 8)) == 8) {
			error = 0;
			iff->scan += 8;
			iff->cn.size = REVERSE_LONG(iff->cn.size);
			iff->cn.scan = 0;
		} else {
			if (error == -1) {
				error = IFFERR_READ;
			}	else if (error == 0) {
				error = IFFERR_EOF;
			}
		}
	}

	return (error);
}


/****************************************************************************
*
* NAME
*     WriteChunkHeader - Write an IFF chunk identification header.
*
* SYNOPSIS
*     Error = WriteChunkHeader(IFFHandle, ID, Size)
*
*     long WriteChunkHeader(IFFHandle *, long, long);
*
* FUNCTION
*     Write an IFF identification header to the files data stream.
*
* INPUTS
*     IFFHandle - Pointer to IFFHandle structure.
*     ID        - ID code of chunk.
*     Size      - Size of chunk in bytes (WORD aligned).
*
* RESULT
*     Error - 0 if successful or IFFERR_??? error code.
*
****************************************************************************/

long WriteChunkHeader(IFFHandle *iff, long id, long size)
{
	long error = 0;

	/* Make sure it is okay to write. */
	if (iff->flags & IFFF_WRITE) {
		iff->cn.id = id;
		iff->cn.size = REVERSE_LONG(size);
		iff->cn.scan = 0;

		if (write(iff->fh, &iff->cn, 8) == 8) {
			iff->scan += 8;
		} else {
			error = IFFERR_WRITE;
		}
	}

	return (error);
}


/****************************************************************************
*
* NAME
*     WriteChunk - Write an IFF chunk with data from a buffer.
*
* SYNOPSIS
*     Actual = WriteChunk(IFFHandle, ID, Buffer, Size)
*
*     long WriteChunk(IFFHandle *, long, char *, long);
*
* FUNCTION
*     Write a IFF chunk at the current file position.
*
* INPUTS
*     IFFHandle - Pointer to IFFHandle structure.
*     ID        - ID code of chunk.
*     Buffer    - Pointer to buffer area with bytes to be written.
*     Size      - Number of bytes to write.
*
* RESULT
*     Actual - (positive) Bytes written or (negative) IFFERR_??? error code.
*
****************************************************************************/

long WriteChunk(IFFHandle *iff, long id, char *buffer, long size)
{
	Context cn;
 	long    actual;

	/* Make sure we can write to this file. */
	if (iff->flags & IFFF_WRITE) {
		cn.id = id;
	  cn.size = REVERSE_LONG(size);

		/* Write chunk header. */
		if (write(iff->fh, &cn, 8) == 8) {
			iff->scan += 8;
			iff->cn.scan += 8;

			/* Write chunk data. */
			actual = write(iff->fh, buffer, size);

			if (actual == size) {
				iff->scan += actual;
				iff->cn.scan += actual;

				/* Write chunk padding if necessary. */
				if (PADSIZE(size) > size) {
					id = 0;

					if (write(iff->fh, &id, 1) == 1) {
						iff->scan++;
						iff->cn.scan++;
					} else {
						actual = IFFERR_WRITE;
					}
				}
			} else {
				actual = IFFERR_WRITE;
			}
		} else {
			actual = IFFERR_WRITE;
		}
	} else {
		actual = IFFERR_WRITE;
	}

	return (actual);
}


/****************************************************************************
*
* NAME
*     WriteChunkBytes - Write data from a buffer to the IFF stream.
*
* SYNOPSIS
*     Actual = WriteChunkBytes(IFFHandle, Buffer, Size)
*
*     long WriteChunk(IFFHandle *, char *, long);
*
* FUNCTION
*     Write a IFF chunk at the current file position.
*
* INPUTS
*     IFFHandle - Pointer to IFFHandle structure.
*     Buffer    - Pointer to buffer area with bytes to be written.
*     Size      - Number of bytes to write.
*
* RESULT
*     Actual - (positive) Bytes written or (negative) IFFERR_??? error code.
*
****************************************************************************/

long WriteChunkBytes(IFFHandle *iff, char *buffer, long size)
{
	long actual;

	/* Make sure we can write to this file. */
	if (iff->flags & IFFF_WRITE) {

		/* Write data. */
		if ((actual = (unsigned short)write(iff->fh, buffer, size)) == size) {
			iff->scan += actual;
			iff->cn.scan += actual;
		} else {
			actual = IFFERR_WRITE;
		}
	} else {
		actual = IFFERR_WRITE;
	}

	return (actual);
}


/****************************************************************************
*
* NAME
*     ReadChunkBytes - Read data from a chunk into a buffer.
*
* SYNOPSIS
*     Actual = ReadChunkBytes(IFFHandle, Buffer, Length)
*
*     long ReadChunkBytes(IFFHandle *, char *, long);
*
* FUNCTION
*     Read in 'Length' number of bytes from the current chunk context.
*     If the specified length exceeds the number of bytes remaining in the
*     chunk ReadChunkBytes() will read in only the number of remaining
*     bytes. ReadChunkBytes() will never read beyond the scope of the
*     current chunk.
*
* INPUTS
*     IFFHandle - Pointer to IFFHandle structure.
*     Buffer    - Pointer to buffer to read data into.
*     Length    - Number of bytes to read.
*
* RESULT
*     Actual - (positive) Bytes written or (negative) IFFERR_??? error code.
*
****************************************************************************/

long ReadChunkBytes(IFFHandle *iff, char *buffer, long size)
{
	long actual;

	/* If the actual bytes remaining in the current chunk is less than
	 * the requested bytes to read then adjust the read request size
	 * to only read in the bytes that remain in the chunk.
	 */
	actual = (iff->cn.size - iff->cn.scan);

	if (size > actual) {
		size = actual;
	}

	/* Read in the requested number of bytes. */
	if ((actual = read(iff->fh, buffer, size)) != size) {
		actual = IFFERR_READ;
	} else {
		iff->scan += actual;
		iff->cn.scan += actual;
	}

	return (actual);
}


/****************************************************************************
*
* NAME
*     SkipChunkBytes - Skip bytes in a chunk.
*
* SYNOPSIS
*     Error = SkipChunkBytes(IFFHandle, Skip)
*
*     long SkipChunkBytes(IFFHandle *, long);
*
* FUNCTION
*     Skip the specified number of bytes of the chunk.
*
* INPUTS
*     IFFHandle - Pointer to IFFHandle structure.
*     Skip      - Number of bytes to skip.
*
* RESULT
*     Error - 0 if successful or FAIL_??? error code.
*
****************************************************************************/

long SkipChunkBytes(IFFHandle *iff, long skip)
{
	long error = 0;

	if (lseek(iff->fh, skip, SEEK_CUR) == -1) {
		error = IFFERR_READ;
	} else {
		iff->scan += skip;
		iff->cn.scan += skip;
	}

	return (error);
}


/****************************************************************************
*
* NAME
*     FindChunk - Scan for a specific chunk name.
*
* SYNOPSIS
*     Error = FindChunk(IFFHandle, ID)
*
*     long FindChunk(IFFHandle *, long);
*
* FUNCTION
*     Scan from the current file position for the next occurance of the
*     specified chunk ID. When a match is found the function will return
*     with the matching chunk as the current context.
*
* INPUTS
*     IFFHandle - Pointer to IFFHandle structure.
*     ID        - ID code of chunk.
*
* RESULT
*     Error - 0 if successful or FAIL_??? error code.
*
****************************************************************************/

long FindChunk(IFFHandle *iff, long id)
{
	long found = 0;
	long error = 0;

	/* Invalid handle check. */
	if (iff != NULL) {

		/* Scan until we have a match or an error. */
		while ((found == 0) && !(error = ReadChunkHeader(iff))) {

			/* If we found a match the terminate scan, otherwise skip this
			 * chunk and process the next.
			 */
			if (iff->cn.id == id) {
				found = 1;
			} else {
				error = SkipChunkBytes(iff, PADSIZE(iff->cn.size));
			}
		}
	}

	return (error);
}


/****************************************************************************
*
* NAME
*     IDtoStr - Convert a longword identifier to a NULL-terminated string.
*
* SYNOPSIS
*     String = IDtoStr(ID, Buffer)
*
*     char *IDtoStr(long, char *);
*
* FUNCTION
*     Writes the ASCII equivalent of the given longword ID into buffer as a
*     NULL-terminated string.
*
* INPUTS
*     ID     - Longword ID.
*     Buffer - Character buffer to accept string (at least 5 characters).
*
* RESULT
*     String - The value of "Buffer".
*
****************************************************************************/

char *IDtoStr(long id, char *buf)
{
	memcpy(buf, &id, 4);
	*(buf + 4) = 0;

	return (buf);
}


/****************************************************************************
*
* NAME
*     CurrentFilePos - Get the current file position.
*
* SYNOPSIS
*     Position = CurrentFilePos(IFFHandle)
*
*     long CurrentFilePos(IFFHandle *);
*
* FUNCTION
*     This function returns the offset in bytes of the current file position
*     from the beginning of the IFF.
*
* INPUTS
*     IFFHandle - Pointer to IFFHandle structure.
*
* RESULT
*     Position - Offset in bytes from the beginning of the file to the
*                current position.
*
****************************************************************************/

long CurrentFilePos(IFFHandle *iff)
{
	long offset;

	if ((offset = lseek(iff->fh, 0, SEEK_CUR)) == -1) {
		offset = IFFERR_READ;
	}

	return (offset);
}

