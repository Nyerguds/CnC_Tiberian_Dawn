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
*        C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* PROJECT
*     VQAPlay32 library.
*
* FILE
*     dstream.c
*
* DESCRIPTION
*     DOS IO handler.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     April 10, 1995
*
*----------------------------------------------------------------------------
*
* PUBLIC
*     VQA_InitAsDOS - Initialize IO with the standard DOS handler.
*
* PRIVATE
*     VQADOSHandler - Standard DOS IO handler.
*
****************************************************************************/

#include <fcntl.h>
#include <io.h>
#include "vqaplayp.h"

/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

static long VQADOSHandler(VQAHandle *vqa, long action, void *buffer,
		long nbytes);


/****************************************************************************
*
* NAME
*     VQA_InitAsDOS - Initialize IO with the standard DOS handler.
*
* SYNOPSIS
*     VQA_InitAsDOS(VQA)
*
*     VQA_InitAsDOS(VQAHandle *);
*
* FUNCTION
*     Initialize the IO of the specified handle as a standard DOS access.
*
* INPUTS
*     VQA - Pointer to VQAHandle to initialize as DOS.
*
* RESULT
*     NONE
*
****************************************************************************/

void VQA_InitAsDOS(VQAHandle *vqa)
{
	((VQAHandleP *)vqa)->IOHandler = VQADOSHandler;
}


/****************************************************************************
*
* NAME
*     VQADOSHandler - Standard DOS IO handler.
*
* SYNOPSIS
*     Error = VQADOSHandler(VQA, Action, Buffer, NBytes)
*
*     unsigned long VQADOSHandler(VQAHandle *, long, long, long);
*
* FUNCTION
*      Perform the requested action on the standard DOS file system.
*
* INPUTS
*      VQA    - VQAHandle to operate on.
*      Action - Action to perform.
*      Buffer - Buffer to Read/Write to/from.
*      NBytes - Number of bytes to operate on.
*
* RESULT
*      Error - 0 if successful, otherwise error.
*
****************************************************************************/

static long VQADOSHandler(VQAHandle *vqa, long action, void *buffer,
		long nbytes)
{
	long fh;
	long error;

	fh = vqa->VQAio;

	/* Perform the action specified by the IO command */
	switch (action) {

		/* VQACMD_READ means read NBytes and place it in the memory
		 * pointed to by Buffer.
		 *
		 * Any error code returned will be remapped by VQA library into
		 * VQAERR_READ.
		 */
		case VQACMD_READ:
			error = (read(fh, buffer, nbytes) != nbytes);
			break;

		/* VQACMD_WRITE is analogous to VQACMD_READ.
		 *
		 * Writing is not allowed to the VQA file, VQA library will remap the
		 * error into VQAERR_WRITE.
		 */
		case VQACMD_WRITE:
			error = 1;
			break;

		/* VQACMD_SEEK asks that you perform a seek relative to the current
		 * position. NBytes is a signed number, indicating seek direction
		 * (positive for forward, negative for backward). Buffer has no meaning
		 * here.
		 *
		 * Any error code returned will be remapped by VQA library into
		 * VQAERR_SEEK.
		 */
		case VQACMD_SEEK:
			error = (lseek(fh, nbytes, (long)buffer) == -1);
			break;

		/* VQACMD_OPEN asks that you open the file for access. */
		case VQACMD_OPEN:
			error = open((char *)buffer, (O_RDONLY|O_BINARY));

			if (error != -1) {
				vqa->VQAio = error;
				error = 0;
			}
			break;

		case VQACMD_CLOSE:
			close(fh);
			error = 0;
			break;

		/* VQACMD_INIT means to prepare your IO for reading. This is used for
		 * certain IOs that can't be read immediately upon opening, and need
		 * further preparation. This operation is allowed to fail; the error code
		 * will be returned directly to the client.
		 */
		case VQACMD_INIT:

		/* IFFCMD_CLEANUP means to terminate the transaction with the associated
		 * IO. This is used for IOs that can't simply be closed. This operation
		 * is not allowed to fail; any error returned will be ignored.
		 */
		case VQACMD_CLEANUP:
			error = 0;
			break;
	}

	return (error);
}

