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
*        C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S
*
*----------------------------------------------------------------------------
*
* FILE
*     targa.c
* 
* DESCRIPTION
*     Targa Image File reader. (32-Bit protected mode)
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
*     OpenTarga  - Open Targa image file.
*     CloseTarga - Close Targa image file.
*     LoadTarga  - Load Targa image file.
*     XFlipTarga - X flip the image.
*     YFlipTarga - Y flip the image.
*
* PRIVATE
*     DecodeImageData - Decompress Targa image data.
*
****************************************************************************/

#include <stdio.h>
#include <malloc.h>
#include <mem.h>
#include <io.h>
#include <fcntl.h>
#include <sys\stat.h>
#include "targa.h"

/* Private data declerations. */
static long DecodeImageData(TGAHandle *, char *);
static void InvertImageData(TGAHeader *, char *);

/****************************************************************************
*
* NAME
*     OpenTarga - Open Targa image file.
*
* SYNOPSIS
*     TGAHandle = OpenTarga(Name, Mode)
*
*     TGAHandle *OpenTarga(char *, unsigned short);
*
* FUNCTION
*     Open a Targa image file and read in its header. The file stream will
*     positioned after the ID field (if there is one).
*
* INPUTS
*     Name - Pointer to name of Targa file.
*     Mode - Access mode.
*
* RESULT
*     TGAHandle - Pointer to initialized TGAHandle or NULL if error.
*
****************************************************************************/

TGAHandle *OpenTarga(char *name, unsigned short mode)
{
	TGAHandle *tga;
	long       size;
	long       error = 0;

	/* Allocate TGAHandle */
	if ((tga = (TGAHandle *)malloc(sizeof(TGAHandle))) != NULL) {

		/* Initialize TGAHandle structure. */
		memset((void *)tga, 0, sizeof(TGAHandle));
		tga->mode = mode;

		switch (mode) {

			/* Open targa file for read. */
			case TGA_READMODE:
				if ((tga->fh = open(name, (O_RDONLY|O_BINARY))) != -1) {

					/* Read in header. */
					size = read(tga->fh, &tga->header, sizeof(TGAHeader));

					if (size != sizeof(TGAHeader)) {
						error = 1;
					}

					/* Skip the ID field */
					if (!error && (tga->header.IDLength != 0)) {
						if (lseek(tga->fh, tga->header.IDLength, SEEK_CUR) == -1) {
							error = 1;
						}
					}
				} else {
					error = 1;
				}
				break;

			/* Open targa file for write. */
			case TGA_WRITEMODE:
				if ((tga->fh = open(name, (O_CREAT|O_TRUNC|O_WRONLY|O_BINARY),
						(S_IREAD|S_IWRITE))) == -1) {

					error = 1;
				} else {
					printf("\r");
				}
				break;

			/* Open targa file for read/write.*/
			case TGA_RDWRMODE:
				if ((tga->fh = open(name, (O_RDWR|O_BINARY),
						(S_IREAD|S_IWRITE))) != -1) {

					/* Read in header. */
					size = read(tga->fh, &tga->header, sizeof(TGAHeader));

					if (size != sizeof(TGAHeader)) {
						error = 1;
					}

					/* Skip the ID field */
					if (!error && (tga->header.IDLength != 0)) {
						if (lseek(tga->fh, tga->header.IDLength, SEEK_CUR) == -1) {
							error = 1;
						}
					}
				} else {
					error = 1;
				}
				break;
		}
 
		/* Close on any error! */
		if (error) {
			CloseTarga(tga);
			tga = NULL;
		}
	}

	return (tga);
}


/****************************************************************************
*
* NAME
*     CloseTarga - Close Targa image file.
*
* SYNOPSIS
*     CloseTarga(TGAHandle)
*
*     void CloseTarga(TGAHandle *);
*
* FUNCTION
*     Close the Targa image file and free its handle.
*
* INPUTS
*     TGAHandle - Pointer to TGAHandle returned by OpenTarga().
*
* RESULT
*     NONE
*
****************************************************************************/

void CloseTarga(TGAHandle *tga)
{
	/* Ensure valid handle. */
	if (tga) {

		/* Close the file if it is open. */
		if (tga->fh != -1) close(tga->fh);

		/* Free TGAHandle */
		free(tga);
	}
}


/****************************************************************************
*
* NAME
*     LoadTarga - Load Targa Image File.
*
* SYNOPSIS
*     Error = LoadTarga(Name, Palette, ImageBuffer)
*
*     long LoadTarga(char *, char *, char *);
*
* FUNCTION
*     Open and load the Targa into the specified buffers. If either buffer
*     pointer is NULL then that field will not be processed.
*
* INPUTS
*     Name        - Name of Targa image file to load.
*     Palette     - Pointer to buffer to load the palette into.
*     ImageBuffer - Pointer to buffer to load the image data into.
*
* RESULT
*     Error - 0 if successful, or TGAERR_??? error code.
*
****************************************************************************/

long LoadTarga(char *name, char *palette, char *image)
{
	TGAHandle *tga;
	long       size;
	long       depth;
	long       i,n;
	char       c;
	long       error = 0;

	/* Open the Targa */
	if ((tga = OpenTarga(name, TGA_READMODE)) != NULL) {

		/* Process ColorMap (palette) */
		if (tga->header.ColorMapType == 1) {
			depth = (tga->header.CMapDepth >> 3);
			size = (tga->header.CMapLength * depth);

			/* Load the palette from the TGA if a palette buffer is provided
			 * otherwise we will skip it.
			 */
			if ((palette != NULL) && (tga->header.CMapLength > 0)) {

				/* Adjust palette to the starting color entry. */
				palette += (tga->header.CMapStart * depth);

				/* Read in the palette. */
				if (read(tga->fh, palette, size) == size) {

					/* Swap the byte ordering of the palette entries. */
					for (i = 0; i < tga->header.CMapLength; i++) {
						#if(0)
						for (n = 0; n < depth; n++) {
							c = *(palette + n);
							*(palette + n) = *(palette + ((depth - 1) - n));
							*(palette + ((depth - 1) - n)) = c;
						}
						#else
						c = *palette;
						*palette = *(palette + (depth - 1));
						*(palette + (depth - 1)) = c;
						#endif

						/* Next entry */
						palette += depth;
					}
				} else {
					error = TGAERR_READ;
				}
			} else {
				if (lseek(tga->fh, size, SEEK_CUR) == -1) {
					error = TGAERR_READ;
				}
			}
		}

		/* Load the image data from the TGA if an image buffer is provided
		 * otherwise we are done.
		 */
		if (!error && (image != NULL)) {
			depth = (tga->header.PixelDepth >> 3);
			size = ((tga->header.Width * tga->header.Height) * depth);

			switch (tga->header.ImageType) {
				case TGA_CMAPPED:
					if (read(tga->fh, image, size) != size) {
						error = TGAERR_READ;
					}
					break;

				case TGA_TRUECOLOR:
					if (read(tga->fh, image, size) == size) {
						InvertImageData(&tga->header, image);
					} else {
						error = TGAERR_READ;
					}
					break;

				case TGA_CMAPPED_ENCODED:
					error = DecodeImageData(tga, image);
					break;

				case TGA_TRUECOLOR_ENCODED:
					if ((error = DecodeImageData(tga, image)) == NULL) {
						InvertImageData(&tga->header, image);
					}
					break;

				default:
					error = TGAERR_NOTSUPPORTED;
					break;
			}

			/* Arrange the image so that the origin position (coordinate 0,0)
			 * is the upperleft hand corner of the image.
			 */
			if (!error) {
				if (tga->header.ImageDescriptor & TGAF_XORIGIN) {
					XFlipTarga(&tga->header, image);
				}

				if ((tga->header.ImageDescriptor & TGAF_YORIGIN) == 0) {
					YFlipTarga(&tga->header, image);
				}
			}
		}

		/* Close the Targa */
		CloseTarga(tga);
	} else {
		error = TGAERR_OPEN;
	}

	return (error);
}


/****************************************************************************
*
* NAME
*     SaveTarga - Save a Targa Image File.
*
* SYNOPSIS
*     Error = SaveTarga(Name, TGAHeader, Palette, ImageBuffer)
*
*     long SaveTarga(char *, TGAHeader *, char *, char *);
*
* FUNCTION
*
* INPUTS
*     Name        - Pointer to name of file to save.
*     TGAHeader   - Pointer to initialized targa header structure.
*     Palette     - Pointer to palette.
*     ImageBuffer - Pointer to raw image data.
*
* RESULT
*     Error - 0 if successful, or TGAERR_??? error code.
*
****************************************************************************/

long SaveTarga(char *name, TGAHeader *tgahd, char *palette, char *image)
{
	TGAHandle *tga;
	long       size;
	long       depth;
	char      *temppal;
	char      *ptr;
	long       i,n;
	char       c;
	long       error = 0;

	/* Open the Targa for write. */
	if ((tga = OpenTarga(name, TGA_WRITEMODE)) != NULL) {

		/* Write the header. */
		if (write(tga->fh, tgahd, sizeof(TGAHeader)) != sizeof(TGAHeader)) {
			error = TGAERR_WRITE;
		}

		/* Write the palette. */
		if (!error && (palette != NULL) && (tgahd->CMapLength > 0)) {

			/* Adjust palette to the starting color entry. */
			depth = (tgahd->CMapDepth >> 3);
			palette += (tgahd->CMapStart * depth);
			size = (tgahd->CMapLength * depth);

			/* Allocate temporary buffer for palette manipulation. */
			if ((temppal = (char *)malloc(size)) != NULL) {
				memcpy(temppal, palette, size);
				ptr = temppal;

				/* Swap the byte ordering of the palette entries. */
				for (i = 0; i < tga->header.CMapLength; i++) {
					for (n = 0; n < (depth >> 1); n++) {
						c = *(ptr + n);
						*(ptr + n) = *(ptr + (depth - n));
						*(ptr + (depth - n)) = c;
					}

					/* Next entry */
					palette += depth;
				}
				
				/* Write the palette. */
				if (write(tga->fh, temppal, size) != size) {
					error = TGAERR_WRITE;
				}

				/* Free temporary palette buffer. */
				free(temppal);
			} else {
				error = TGAERR_NOMEM;
			}
		}

		/* Invert truecolor data. */
		if (tgahd->ImageType == TGA_TRUECOLOR) {
			InvertImageData(tgahd, image);
		}

		/* Write the image. */
		if (!error && (image != NULL)) {
			depth = (tgahd->PixelDepth >> 3);
			size = (((tgahd->Width * tgahd->Height)) * depth);

			if (write(tga->fh, image, size) != size) {
				error = TGAERR_WRITE;
			}
		}

		/* Close targa file. */
		CloseTarga(tga);
	} else {
		error = TGAERR_OPEN;
	}

	return (error);
}


/****************************************************************************
*
* NAME
*     XFlipTarga - X flip the image.
*
* SYNOPSIS
*     XFlipTarga(TGAHeader, Image)
*
*     void XFlipTarga(TGAHeader *, char *);
*
* FUNCTION
*     Flip the image in memory on its X axis. (left to right)
*
* INPUTS
*     TGAHeader - Pointer to initialized TGAHeader structure.
*     Image     - Pointer to image buffer.
*
* RESULT
*     NONE
*
****************************************************************************/

void XFlipTarga(TGAHeader *tga, char *image)
{
	char *ptr,*ptr1;
	long  x,y,d;
	char  v,v1;
	char  depth;

	/* Pixel depth in bytes. */
	depth = (tga->PixelDepth >> 3);

	for (y = 0; y < tga->Height; y++) {
		ptr = (image + ((tga->Width * depth) * y));
		ptr1 = (ptr + ((tga->Width * depth) - depth));

		for (x = 0; x < (tga->Width / 2); x++) {
			for (d = 0; d < depth; d++) {
				v = *(ptr + d);
				v1 = *(ptr1 + d);
				*(ptr + d) = v1;
				*(ptr1 + d) = v;
			}

			ptr += depth;
			ptr1 -= depth;
		}
	}
}


/****************************************************************************
*
* NAME
*     YFlipTarga - Y flip the image.
*
* SYNOPSIS
*     YFlipTarga(TGAHeader, Image)
*
*     void YFlipTarga(TGAHeader *, char *);
*
* FUNCTION
*     Flip the image in memory on its Y axis. (top to bottom)
*
* INPUTS
*     TGAHeader - Pointer to initialized TGAHeader structure.
*     Image     - Pointer to image buffer.
*
* RESULT
*     NONE
*
****************************************************************************/

void YFlipTarga(TGAHeader *tga, char *image)
{
	char *ptr,*ptr1;
	long  x,y;
	char  v,v1;
	char  depth;

	/* Pixel depth in bytes. */
	depth = (tga->PixelDepth >> 3);

	for (y = 0; y < (tga->Height >> 1); y++) {

		/* Compute address of lines to exchange. */
		ptr = (image + ((tga->Width * y) * depth));
		ptr1 = (image + ((tga->Width * (tga->Height - 1)) * depth));
		ptr1 -= ((tga->Width * y) * depth);

		/* Exchange all the pixels on this scan line. */
		for (x = 0; x < (tga->Width * depth); x++) {
			v = *ptr;
			v1 = *ptr1;
			*ptr = v1;
			*ptr1 = v;
			ptr++;
			ptr1++;
		}
	}
}


/****************************************************************************
*
* NAME
*     DecodeImageData - Decompress Targa image data.
*
* SYNOPSIS
*     Error = DecodeImageData(TGAHandle, ImageBuffer)
*
*     long DecodeImageData(TGAHandle *, char *);
*
* FUNCTION
*     Decode the RLE compressed image data into the specified buffer from
*     the file I/O stream.
*
* INPUTS
*     TGAHandle   - Pointer to TGAHandle returned by OpenTarga().
*     ImageBuffer - Pointer to buffer to decompress image into.
*
* RESULT
*     Error - 0 if successful, or TGAERR_??? error code.
*
****************************************************************************/

static long DecodeImageData(TGAHandle *tga, char *image)
{
	char          *packet;
	unsigned char  count;
	unsigned char  depth;
	unsigned long  pixel_count;
	unsigned long  size;
	unsigned long  c,i;
	long           error = 0;

	/* Compute pixel depth in bytes. */
	depth = (tga->header.PixelDepth >> 3);

	/* Total number of pixels compressed in this image. */
	pixel_count = (tga->header.Width * tga->header.Height);

	/* Allocate packet buffer to hold maximum encoded data run. */
	if ((packet = (char *)malloc(128 * depth)) != NULL) {
		while ((pixel_count > 0) && !error) {

			/* Read count. */
			if (read(tga->fh, &count, 1) == 1) {

				/* If bit 8 of the count is set then we have a run of pixels,
				 * otherwise the data is raw pixels.
				 */
				if (count & 0x80) {
					count &= 0x7F;
					count++;

					/* Read in run pixel. */
					if (read(tga->fh, packet, depth) == depth) {

						/* Repeat the pixel for the run count in the image buffer. */
						for (c = 0; c < count; c++) {
							for (i = 0; i < depth; i++) {
								*image++ = *(packet + i);
							}
						}
					} else {
						error = TGAERR_READ;
					}
				} else {
					count++;
					size = (count * depth);

					/* Read in raw pixels. */
					if (read(tga->fh, packet, size) == size) {

						/* Copy the raw pixel data into the image buffer. */
						memcpy(image, packet, size);
						image += size;
					} else {
						error = TGAERR_READ;
					}
				}

				/* Adjust the pixel count. */
				pixel_count -= count;
			} else {
				error = TGAERR_READ;
			}
		}

		/* Free packet buffer. */
		free(packet);
	} else {
		error = TGAERR_NOMEM;
	}

	return (error);
}


/****************************************************************************
*
* NAME
*     InvertImageData - Invert TrueColor image data.
*
* SYNOPSIS
*     InvertImageData(TGAHeader, ImageData)
*
*     void InvertImageData(TGAHeader *, char *);
*
* FUNCTION
*
* INPUTS
*     TGAHeader - Pointer to initialized TGAHeader structure.
*     ImageData - Pointer to TrueColor image data.
*
* RESULT
*     NONE
*
****************************************************************************/

static void InvertImageData(TGAHeader *tga, char *image)
{
	long depth;
	long pixel_count;
	long i;
	char c;

	/* Compute the pixel depth in bytes. */
	depth = (tga->PixelDepth >> 3);

	/* Total number of pixels in this image. */
	pixel_count = (tga->Width * tga->Height);

	/* 16-bit pixel layout is different that 24-bit and 32-bit. */
	if (depth > 2) {
		while (pixel_count > 0) {
			for (i = 0; i < (depth / 2); i++) {
				c = *(image + i);
				*(image + i) = *(image + ((depth - 1) - i));
				*(image + ((depth - 1) - i)) = c;
			}

			/* Next pixel */
			pixel_count--;
			image += depth;
		}
	} else {
	}
}


