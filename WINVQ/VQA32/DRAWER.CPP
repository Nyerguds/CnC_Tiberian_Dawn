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
*     VQAPlay32 library. (32-Bit protected mode)
*
* FILE
*     drawer.c
*
* DESCRIPTION
*     Frame drawing and page flip control.
*
* PROGRAMMER
*     Bill Randolph
*     Denzil E. Long, Jr.
*
* DATE
*     June 26, 1995
*
*----------------------------------------------------------------------------
*
* PUBLIC
*     VQA_Configure_Drawer - Configure the drawer routines.
*
* PRIVATE
*     Select_Frame             - Selects frame to draw and preforms frame
*                                skip.
*     Prepare_Frame            - Process/Decompress frame information.
*     DrawFrame_Xmode          - Draws a frame directly to Xmode screen.
*     DrawFrame_XmodeBuf       - Draws a frame in Xmode format to a buffer.
*     DrawFrame_XmodeVRAM      - Draws a frame in Xmode with resident
*                                Codebook.
*     PageFlip_Xmode           - Page flip Xmode display.
*     DrawFrame_MCGA           - Draws a frame directly to MCGA screen.
*     PageFlip_MCGA            - Page flip MCGA display.
*     DrawFrame_MCGABuf        - Draws a frame in MCGA format to a buffer.
*     PageFlip_MCGABuf         - Page flip a buffered MCGA display.
*     DrawFrame_VESA640        - Draws a frame in VESA640 format.
*     DrawFrame_VESA320_32K    - Draws a frame to VESA320_32K screen.
*     DrawFrame_VESA320_32KBuf - Draws a frame in VESA320_32K format to a
*                                buffer.
*     PageFlip_VESA            - Page flip VESA display.
*     DrawFrame_Buffer         - Draw a frame to a buffer.
*     PageFlip_Nop             - Do nothing page flip.
*     UnVQ_Nop                 - Do nothing UnVQ.
*     Mask_Rect                - Sets non-drawable rectangle in image.
*     Mask_Pointers            - Mask vector pointer that are in the mask
*                                rectangle.
*
****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <conio.h>
#include <dos.h>
#include <mem.h>
#include "vq.h"
#include "unvq.h"
#include "vqaplayp.h"
#include <vqm32\all.h>
#include "caption.h"

/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/
static long Select_Frame(VQAHandleP *vqap);
static void Prepare_Frame(VQAData *vqabuf);

#if(VQAMCGA_ON)
static long DrawFrame_MCGABuf(VQAHandle *vqa);
static long PageFlip_MCGABuf(VQAHandle *vqa);
static long DrawFrame_MCGA(VQAHandle *vqa);
static long PageFlip_MCGA(VQAHandle *vqa);
#endif /* VQAMCGA_ON */

#if(VQAXMODE_ON)
static long DrawFrame_XmodeBuf(VQAHandle *vqa);
static long DrawFrame_Xmode(VQAHandle *vqa);
static long DrawFrame_XmodeVRAM(VQAHandle *vqa);
static void PageFlip_Xmode(VQAHandle *vqabuf);
#endif /* VQAXMODE_ON */

#if(VQAVESA_ON)
static long DrawFrame_VESA640(VQAHandle *vqa);
static long DrawFrame_VESA320_32K(VQAHandle *vqa);
static long DrawFrame_VESA320_32KBuf(VQAHandle *vqa);
static void PageFlip_VESA(VQAHandle *vqabuf);
#endif /* VQAVESA_ON */

static long DrawFrame_Buffer(VQAHandle *vqa);
static long PageFlip_Nop(VQAHandle *vqa);

#ifndef PHARLAP_TNT
static void __cdecl UnVQ_Nop(unsigned char *codebook, unsigned char *pointers,
		unsigned char *buffer, unsigned long blocksperrow,
		unsigned long numrows, unsigned long bufwidth);
#else
static void __cdecl UnVQ_Nop(unsigned char *codebook, unsigned char *pointers,
		FARPTR buffer, unsigned long blocksperrow, unsigned long numrows,
		unsigned long bufwidth);
#endif

#if(0)
static void Mask_Rect(VQAHandle *vqa, unsigned long x1, unsigned long y1,
		unsigned long x2, unsigned long y2);
static void Mask_Pointers(VQAData *vqabuf);
#endif


/****************************************************************************
*
* NAME
*     VQA_GetPalette - Get the palette used in the movie.
*
* SYNOPSIS
*     Palette = VQA_GetPalette(VQA)
*
*     char *VQA_GetPalette(VQAHandle *);
*
* FUNCTION
*     Retrieve the address of the current palette used in the movie. If there
*     isn't a palette available then a NULL value will be returned.
*
* INPUTS
*     VQA - Pointer to VQAHandle to get palette for.
*
* RESULT
*     Palette - Pointer to palette or NULL if no palette available.
*
****************************************************************************/

unsigned char *VQA_GetPalette(VQAHandle *vqa)
{
	VQADrawer *drawer;
	unsigned char *palette = NULL;

	/* Dereference commonly used data members for quick access. */
	drawer = &((VQAHandleP *)vqa)->VQABuf->Drawer;

	if (drawer->CurPalSize > 0) {
		palette = drawer->Palette_24;
	}

	return (palette);
}


/****************************************************************************
*
* NAME
*     VQA_GetPaletteSize - Get the size of the palette used in the movie.
*
* SYNOPSIS
*     PalSize = VQA_GetPaletteSize(VQA)
*
*     long VQA_GetPaletteSize(VQAHandle *);
*
* FUNCTION
*     Retrieve the size of the current palette used in the movie. If there
*     isn't a palette available then a zero size will be returned.
*
* INPUTS
*     VQA - Pointer to VQAHandle to get palette for.
*
* RESULT
*     PalSize - Size in bytes of the current palette.
*
****************************************************************************/

long VQA_GetPaletteSize(VQAHandle *vqa)
{
	VQADrawer *drawer;

	/* Dereference commonly used data members for quick access. */
	drawer = &((VQAHandleP *)vqa)->VQABuf->Drawer;

	return (drawer->CurPalSize);
}


/****************************************************************************
*
* NAME
*     VQA_Set_DrawBuffer - Set the buffer to draw the images to.
*
* SYNOPSIS
*     VQA_Set_DrawBuffer(VQA, Buffer, Width, Height, XPos, YPos)
*
*     void VQA_Set_DrawBuffer(VQAHandle *, unsigned char *,
*                             unsigned long, unsigned long, unsigned long,
*                             unsigned long);
*
* FUNCTION
*     Set the draw buffer to the buffer provided by the client.
*
* INPUTS
*     VQA    - Pointer to VQAHandle to set buffer for.
*     Buffer - Pointer to new image buffer.
*     Width  - Width of the buffer in pixels.
*     Height - Height of the buffer in pixels.
*     XPos   - X pixel position in buffer to draw image.
*     YPos   - Y pixel position in buffer to draw image.
*
* RESULT
*     NONE
*
****************************************************************************/

void VQA_Set_DrawBuffer(VQAHandle *vqa, unsigned char *buffer,
		unsigned long width, unsigned long height,
		long xpos, long ypos)
{
	VQAHeader *header;
	VQADrawer *drawer;
	VQAConfig *config;
	long      origin;

	/* Dereference commonly used data members for quick access. */
	header = &((VQAHandleP *)vqa)->Header;
	drawer = &((VQAHandleP *)vqa)->VQABuf->Drawer;
	config = &((VQAHandleP *)vqa)->Config;
	origin = (config->DrawFlags & VQACFGF_ORIGIN);

	/* Set the drawer buffer information. */
	drawer->ImageBuf = buffer;
	drawer->ImageWidth = width;
	drawer->ImageHeight = height;

	/*-------------------------------------------------------------------------
	 * SET THE DRAW POSITION OF THE MOVIE.
	 *
	 * X1 = -1 -- Center image of the X axis, otherwise use X1 value.
	 * Y1 = -1 -- Center image of the Y axis, otherwise use Y1 value.
	 *-----------------------------------------------------------------------*/
	if ((xpos == -1) && (ypos == -1)) {

		#if(VQAVIDEO_ON)
		drawer->X1 = ((drawer->Display->XRes - header->image_width) / 2);
		drawer->Y1 = ((drawer->Display->YRes - header->image_height) / 2);
		#else  /* VQAVIDEO_ON */
		drawer->X1 = ((width - header->ImageWidth) / 2);
		drawer->Y1 = ((height - header->ImageHeight) / 2);
		#endif /* VQAVIDEO_ON */

		drawer->X2 = ((drawer->X1 + header->ImageWidth) - 1);
		drawer->Y2 = ((drawer->Y1 + header->ImageHeight) - 1);
	} else {
		switch (origin) {
			default:
			case VQACFGF_TOPLEFT:
				drawer->X1 = xpos;
				drawer->Y1 = ypos;
				drawer->X2 = ((drawer->X1 + header->ImageWidth) - 1);
				drawer->Y2 = ((drawer->Y1 + header->ImageHeight) - 1);
				break;

			case VQACFGF_BOTLEFT:
				drawer->X1 = xpos;
				drawer->Y1 = (height - ypos);
				drawer->X2 = ((drawer->X1 + header->ImageWidth) - 1);
				drawer->Y2 = ((drawer->Y2 - header->ImageHeight) - 1);
				break;

			case VQACFGF_BOTRIGHT:
				drawer->X1 = (width - xpos);
				drawer->Y1 = (height - ypos);
				drawer->X2 = (drawer->X1 - header->ImageWidth);
				drawer->Y2 = (drawer->Y1 - header->ImageHeight);
				break;
		}
	}

	/* Pre-compute the draw offset for speed. */
	drawer->ScreenOffset = ((width * drawer->Y1) + drawer->X1);
}


/****************************************************************************
*
* NAME
*     VQA_Configure_Drawer - Configure the drawer routines.
*
* SYNOPSIS
*     VQA_Configure_Drawer(VQA)
*
*     void VQA_Configure_Drawer(VQAHandleP *);
*
* FUNCTION
*     Configure the drawing system for the current movie and configuration
*     options.
*
* INPUTS
*     VQA - Pointer to private VQAHandle.
*
* RESULT
*     NONE
*
****************************************************************************/

void VQA_Configure_Drawer(VQAHandleP *vqap)
{
	VQAData   *vqabuf;
	VQAConfig *config;
	VQAHeader *header;
	VQADrawer *drawer;
	long      origin;
	long      blkdim;

	/* Dereference commonly used data members for quicker access. */
	vqabuf = vqap->VQABuf;
	drawer = &vqabuf->Drawer;
	header = &vqap->Header;
	config = &vqap->Config;
	origin = (config->DrawFlags & VQACFGF_ORIGIN);

	/*-------------------------------------------------------------------------
	 * SET THE DRAW POSITION OF THE MOVIE.
	 *
	 * X1 = -1 -- Center image of the X axis, otherwise use X1 value.
	 * Y1 = -1 -- Center image of the Y axis, otherwise use Y1 value.
	 *-----------------------------------------------------------------------*/
	if ((config->X1 == -1) && (config->Y1 == -1)) {

		#if(VQAVIDEO_ON)
		drawer->X1 = ((drawer->Display->XRes - header->image_width) / 2);
		drawer->Y1 = ((drawer->Display->YRes - header->image_height) / 2);
		#else  /* VQAVIDEO_ON */
		drawer->X1 = ((drawer->ImageWidth - header->ImageWidth) / 2);
		drawer->Y1 = ((drawer->ImageHeight - header->ImageHeight) / 2);
		#endif /* VQAVIDEO_ON */

		drawer->X2 = ((drawer->X1 + header->ImageWidth) - 1);
		drawer->Y2 = ((drawer->Y1 + header->ImageHeight) - 1);
	} else {
		switch (origin) {
			default:
			case VQACFGF_TOPLEFT:
				drawer->X1 = config->X1;
				drawer->Y1 = config->Y1;
				drawer->X2 = ((drawer->X1 + header->ImageWidth) - 1);
				drawer->Y2 = ((drawer->Y1 + header->ImageHeight) - 1);
				break;

			case VQACFGF_BOTLEFT:
				drawer->X1 = config->X1;
				drawer->Y1 = (drawer->ImageHeight - config->Y1);
				drawer->X2 = ((drawer->X1 + header->ImageWidth) - 1);
				drawer->Y2 = ((drawer->Y2 - header->ImageHeight) - 1);
				break;

			case VQACFGF_BOTRIGHT:
				drawer->X1 = (drawer->ImageWidth - config->X1);
				drawer->Y1 = (drawer->ImageHeight - config->Y1);
				drawer->X2 = (drawer->X1 - header->ImageWidth);
				drawer->Y2 = (drawer->Y1 - header->ImageHeight);
				break;
		}
	}

	/*-------------------------------------------------------------------------
	 * INITIALIZE THE UNVQ ROUTINE FOR THE SPECIFIED VIDEO MODE AND BLOCK SIZE.
	 *-----------------------------------------------------------------------*/

	/* Pre-compute commonly used values for speed. */
	drawer->BlocksPerRow = header->ImageWidth / header->BlockWidth;
	drawer->NumRows = header->ImageHeight / header->BlockHeight;
	drawer->NumBlocks = drawer->BlocksPerRow * drawer->NumRows;
	blkdim = BLOCK_DIM(header->BlockWidth, header->BlockHeight);

	/* Initialize draw routine vectors to a NOP routine in order to prevent
	 * a crash.
	 */
	vqabuf->UnVQ = UnVQ_Nop;
	vqabuf->Page_Flip = PageFlip_Nop;

	/* If the client specifies buffering then go ahead an set the unvq
	 * vector. All of the buffered modes use the same unvq routines.
	 */
	if (config->DrawFlags & VQACFGF_BUFFER) {
		switch (blkdim) {
			#if(VQABLOCK_2X2)
			case BLOCK_2X2:
				vqabuf->UnVQ = UnVQ_2x2;
				break;
			#endif

			#if(VQABLOCK_2X3)
			case BLOCK_2X3:
				vqabuf->UnVQ = UnVQ_2x3;
				break;
			#endif

			#if(VQABLOCK_4X2)
			case BLOCK_4X2:
				vqabuf->UnVQ = UnVQ_4x2;
				break;
			#endif

			#if(VQABLOCK_4X4)
			case BLOCK_4X4:
				vqabuf->UnVQ = UnVQ_4x4;
				break;
			#endif

			default:
				break;
 		}
 	}

	/* Initialize the draw vectors for the specified video mode. */
	switch (config->Vmode) {

		/* MCGA */
		#if(VQAMCGA_ON)
		case MCGA:
			if (config->DrawFlags & VQACFGF_BUFFER) {
				vqabuf->Draw_Frame = DrawFrame_MCGABuf;
				vqabuf->Page_Flip = PageFlip_MCGABuf;
			} else {
				vqabuf->Draw_Frame = DrawFrame_MCGA;
				vqabuf->Page_Flip = PageFlip_MCGA;

				/* MCGA uses the same unvq routines that are used for unvqing
				 * to a buffer because MCGA mode is just another buffer. However,
				 * instead of drawing to an allocated RAM buffer we are drawing
				 * directly to the VRAM video buffer.
				 */
				switch (blkdim) {
					#if(VQABLOCK_2X2)
					case BLOCK_2X2:
						vqabuf->UnVQ = UnVQ_2x2;
						break;
					#endif

					#if(VQABLOCK_2X3)
					case BLOCK_2X3:
						vqabuf->UnVQ = UnVQ_2x3;
						break;
					#endif

					#if(VQABLOCK_4X2)
					case BLOCK_4X2:
						#if(!VQAWOOFER_ON)
						vqabuf->UnVQ = UnVQ_4x2;
						#else
						if (config->DrawFlags & VQACFGF_WOOFER) {
							vqabuf->UnVQ = UnVQ_4x2_Woofer;
						} else {
							vqabuf->UnVQ = UnVQ_4x2;
						}
						#endif
						break;
					#endif

					#if(VQABLOCK_4X4)
					case BLOCK_4X4:
						vqabuf->UnVQ = UnVQ_4x4;
						break;
					#endif
				}
			}

			/* Pre-compute the draw offset for speed. */
			drawer->ScreenOffset = ((320 * drawer->Y1) + drawer->X1);
			break;
		#endif /* VQAMCGA_ON */

		/* XMODE */
		#if(VQAXMODE_ON)
		case XMODE_320X200:
		case XMODE_320X240:
			if (config->DrawFlags & VQACFGF_BUFFER) {
				vqabuf->Draw_Frame = DrawFrame_XmodeBuf;
				vqabuf->Page_Flip = PageFlip_Xmode;
			} else {
				vqabuf->Page_Flip = PageFlip_Xmode;

				if (config->DrawFlags & VQACFGF_VRAMCB) {
					vqabuf->Draw_Frame = DrawFrame_XmodeVRAM;

					switch (blkdim) {
						#if(VQABLOCK_4X2)
						case BLOCK_4X2:
							vqabuf->UnVQ = UnVQ_4x2_XmodeCB;
							break;
						#endif /* VQABLOCK_4X2 */
					}
				} else {
					vqabuf->Draw_Frame = DrawFrame_Xmode;

					switch (blkdim) {
						#if(VQABLOCK_4X2)
						case BLOCK_4X2:
							vqabuf->UnVQ = UnVQ_4x2_Xmode;
							break;
						#endif /* VQABLOCK_4X2 */
					}
				}
			}

			/* Pre-compute the draw offset for speed. */
			drawer->ScreenOffset = (((320 / 4) * drawer->Y1) + (drawer->X1 / 4));
			break;
		#endif /* VQAXMODE_ON */

		/* VESA */
		#if(VQAVESA_ON)

		/* Currently this is a buffered mode, but should be optimized for
		 * for screen direct.
		 */
		case VESA_640X480_256:
			vqabuf->Draw_Frame = DrawFrame_VESA640;
			vqabuf->Page_Flip = PageFlip_VESA;
			break;

		case VESA_320X200_32K_1:
			if (config->DrawFlags & VQACFGF_BUFFER) {
				vqabuf->Draw_Frame = DrawFrame_VESA320_32KBuf;
			} else {
				vqabuf->Draw_Frame = DrawFrame_VESA320_32K;

				switch (blkdim) {
					#if(VQABLOCK_4X2)
					case BLOCK_4X2:
						vqabuf->UnVQ = UnVQ_4x2_VESA320_32K;
						break;
					#endif
				}
			}
			break;
		#endif /* VQAVESA_ON */

		/* Purely buffered (Video refresh is up to the client. */
		default:
			vqabuf->Draw_Frame = DrawFrame_Buffer;

			/* Pre-compute the draw offset for speed. */
			drawer->ScreenOffset = ((drawer->ImageWidth * drawer->Y1)+drawer->X1);
			break;
	}
}


/****************************************************************************
*
* NAME
*     Select_Frame - Selects frame to draw and preforms frame skip.
*
* SYNOPSIS
*     Error = Select_Frame(VQA)
*
*     long Select_Frame(VQAHandleP *);
*
* FUNCTION
*     Select a frame to draw. This is were the frame skipping/delay is
*     performed.
*
* INPUTS
*     VQA - Pointer to private VQAHandle.
*
* RESULT
*     Error - 0 if successful, or VQAERR_??? error code.
*
****************************************************************************/

static long Select_Frame(VQAHandleP *vqap)
{
	VQAData      *vqabuf;
	VQADrawer    *drawer;
	VQAConfig    *config;
	VQAFrameNode *curframe;
	long         desiredframe;
	// MEG 11.29.95 - changed from long to unsigned long
	unsigned long curtime;

	/* Dereference commonly used data members for quicker access. */
	config = &vqap->Config;
	vqabuf = vqap->VQABuf;
	drawer = &vqabuf->Drawer;
	curframe = drawer->CurFrame;

	/* Make sure the current frame is drawable. If the frame is not ready
	 * then we must wait for the loader to catch up.
	 */
	if ((curframe->Flags & VQAFRMF_LOADED) == 0) {
		drawer->WaitsOnLoader++;
		return (VQAERR_NOBUFFER);
	}

	/* If single stepping then return with the next frame.*/
	if (config->OptionFlags & VQAOPTF_STEP) {
		drawer->LastFrame = curframe->FrameNum;
		return (0);
	}

	/* Find the frame # we should play (rounded to nearest frame): */
	curtime = VQA_GetTime(vqap);
//	desiredframe = ((curtime * config->FrameRate) / VQA_TIMETICKS);
	// MEG MOD 06.22.95 - Should look for the desired frame to draw, not load,
	// right?
	desiredframe = ((curtime * config->DrawRate) / VQA_TIMETICKS);

	#if(VQAMONO_ON)
	drawer->DesiredFrame = desiredframe;
	#endif

	/* Handle the cases where the player is going so fast that it's not time
	 * to draw this frame yet.
	 *
	 * - If the Drawer is using a slower frame rate than the Loader, use a
	 *   delta-time-based wait; otherwise, use the frame number as the wait.
	 */
	if (config->DrawRate != config->FrameRate) {
		if (curtime - drawer->LastTime < (VQA_TIMETICKS / config->DrawRate)) {
			return (VQAERR_NOT_TIME);
		}
	} else {
		if (curframe->FrameNum > desiredframe) {
			return (VQAERR_NOT_TIME);
		}
	}

	/* Make sure we draw at least 5 frames per second */
	if ((curframe->FrameNum - drawer->LastFrame) >= (config->FrameRate / 5)) {
		drawer->LastFrame = curframe->FrameNum;
		return (0);
	}

	/* If frame skipping is disabled then draw every frame. */
	if (config->DrawFlags & VQACFGF_NOSKIP) {
		drawer->LastFrame = curframe->FrameNum;
		return (0);
	}

	/* Handle the case where the player is going too slow, so we have to skip
	 * some frames:
	 *
	 * - If this is a Key Frame, draw it
	 * - If this frame's # is less than what we're supposed to draw, skip it
	 *   (Because the 1st 'desiredframe' will be 0, FrameNum MUST be typecast
	 *   to signed WORD for the comparison; otherwise, the comparison uses
	 *   UWORDs, and the first frame is always skipped.)
	 * - If this is a palette-set frame, set the palette before skipping it
	 * - Loop until we get the frame we need, or there's no frames available
	 */
	while (1) {

		/* No frame available; return */
		if ((curframe->Flags & VQAFRMF_LOADED) == 0) {
			return (VQAERR_NOBUFFER);
		}

		/* Force drawing of a Key Frame */
		if (curframe->Flags & VQAFRMF_KEY) {
			break;
		}

		/* Skip the frame */
		if (curframe->FrameNum < desiredframe) {

			/* Handle a palette in a skipped frame:
			 *
			 * - Stash the palette in Drawer.Palette_24
			 * - Set the Drawer.Flags VQADRWF_SETPAL bit, to tell the page-flip
			 *   routines that this palette must be set
			 */
			if (curframe->Flags & VQAFRMF_PALETTE) {

				/* Un-LCW if needed */
				if (curframe->Flags & VQAFRMF_PALCOMP) {
					curframe->PaletteSize = LCW_Uncompress((char *)curframe->Palette
							+ curframe->PalOffset, (char *)curframe->Palette,
							vqabuf->Max_Pal_Size);

					curframe->Flags &= ~VQAFRMF_PALCOMP;
				}

				/* Stash the palette */
				memcpy(drawer->Palette_24, curframe->Palette, curframe->PaletteSize);
				drawer->CurPalSize = curframe->PaletteSize;
				drawer->Flags |= VQADRWF_SETPAL;
			}

			/* Invoke callback with NULL screen ptr */
			if (config->DrawerCallback != NULL) {
				if ((config->DrawerCallback(NULL, curframe->FrameNum)) != 0) {
					return (VQAERR_EOF);
				}
			}

			/* Skip the frame */
			curframe->Flags = 0L;
			curframe = curframe->Next;
			drawer->CurFrame = curframe;
			drawer->NumSkipped++;
		} else {
			break;
		}
	}

	drawer->LastFrame = curframe->FrameNum;
	drawer->LastTime = curtime;

	return (0);
}


/****************************************************************************
*
* NAME
*     Prepare_Frame - Process/Decompress frame information.
*
* SYNOPSIS
*     Prepare_Frame(VQAData)
*
*     void Prepare_Frame(VQAData *);
*
* FUNCTION
*     Decompress and preprocess the various frame elements (codebook,
*     pointers, palette, etc...)
*
* INPUTS
*     VQAData - Pointer to VQAData structure.
*
* RESULT
*     NONE
*
****************************************************************************/

static void Prepare_Frame(VQAData *vqabuf)
{
	VQADrawer    *drawer;
	VQAFrameNode *curframe;
	VQACBNode    *codebook;

	/* Dereference commonly used data members for quicker access. */
	drawer = &vqabuf->Drawer;
	curframe = drawer->CurFrame;
	codebook = curframe->Codebook;

	/* Decompress the codebook, if needed */
	if (codebook->Flags & VQACBF_CBCOMP) {

		/* Decompress the codebook. */
		LCW_Uncompress((char *)codebook->Buffer + codebook->CBOffset,
				(char *)codebook->Buffer, vqabuf->Max_CB_Size);

		/* Mark as uncompressed for the next time we use it */
		codebook->Flags &= (~VQACBF_CBCOMP);
	}

	/* Decompress the palette, if needed */
	if (curframe->Flags & VQAFRMF_PALCOMP) {
		curframe->PaletteSize = LCW_Uncompress((char *)curframe->Palette +
				curframe->PalOffset,(char *)curframe->Palette,vqabuf->Max_Pal_Size);

		/* Mark as uncompressed */
		curframe->Flags &= ~VQAFRMF_PALCOMP;
	}

	/* Decompress the pointer data, if needed */
	if (curframe->Flags & VQAFRMF_PTRCOMP) {
		LCW_Uncompress((char *)curframe->Pointers + curframe->PtrOffset,
				(char *)curframe->Pointers, vqabuf->Max_Ptr_Size);

		/* Mark as uncompressed */
		curframe->Flags &= ~VQAFRMF_PTRCOMP;
	}

	/* Mask the pointers */
	#if(0)
	Mask_Pointers(vqabuf);
	#endif
}


#if(VQAXMODE_ON)
/****************************************************************************
*
* NAME
*     DrawFrame_Xmode - Draws a frame in Xmode format (Screen direct).
*
* SYNOPSIS
*     Error = DrawFrame_Xmode(VQA)
*
*     long DrawFrame_Xmode(VQAHandle *);
*
* FUNCTION
*     Algorithm:
*       - Skip frames
*       - UnLCW frame
*       - Un-VQ into video RAM
*       - Wait on Update_Enabled
*       - Set the Flipper's CurFrame
*       - Set Update_Enabled
*       - Go to next frame
*       - User_Update:
*         Flip X-Page
*         Set Palette from Flipper.CurFrame
*
*     This function implements a sort of cooperative multitasking.  If the
*     Drawer hits a "wait state", where it has to wait for Update_Enabled
*     to toggle, it sets a flag and returns.  This flag is checked on entry
*     to see if we need to jump to the proper execution point. This should
*     improve performance on some platforms.
*
*     This routine handles small images by UnVQ'ing into the correct spot on
*     the Xmode screen.
*
* INPUTS
*     VQA - Pointer to VQAHandle.
*
* RESULT
*     Error - 0 if successful, or VQAERR_??? error code.
*
****************************************************************************/

static long DrawFrame_Xmode(VQAHandle *vqa)
{
	VQAData       *vqabuf;
	VQADrawer     *drawer;
	VQAFrameNode  *curframe;
	VQAConfig     *config;
	unsigned char *scrn;
	long          rc;

	/* Dereference data members for quick access */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	drawer = &vqabuf->Drawer;
	config = &((VQAHandleP *)vqa)->Config;

	/* Check our "sleep" state */
	if (!(vqabuf->Flags & VQADATF_DSLEEP)) {

		/* Find the frame to draw */
 		if ((rc = Select_Frame((VQAHandleP *)vqa)) != 0) {
			return (rc);
		}

		/* Uncompress the frame data */
		Prepare_Frame(vqabuf);

		/* Dereference current frame for quicker access */
		curframe = drawer->CurFrame;

		/* Un-VQ the image */
		scrn = GetXHidPage();
		vqabuf->UnVQ(curframe->Codebook->Buffer, curframe->Pointers,
				scrn + drawer->ScreenOffset, drawer->BlocksPerRow,
				drawer->NumRows, 320);

		/* Invoke user's callback routine */
		if (config->DrawerCallback != NULL) {
			if ((config->DrawerCallback(scrn, curframe->FrameNum)) != 0) {
				return (VQAERR_EOF);
			}
		}
	}

	/* Wait for Update_Enabled to be set low */
	if (vqabuf->Flags & VQADATF_UPDATE) {
		vqabuf->Flags |= VQADATF_DSLEEP;
		return (VQAERR_SLEEPING);
	}

	if (vqabuf->Flags & VQADATF_DSLEEP) {
		drawer->WaitsOnFlipper++;
		vqabuf->Flags &= (~VQADATF_DSLEEP);
	}

	/* Dereference current frame for quicker access */
	curframe = drawer->CurFrame;

	/* Update data for mono output */
	drawer->LastFrameNum = curframe->FrameNum;

	/* Tell the flipper which frame to use */
	vqabuf->Flipper.CurFrame = curframe;

	/* Set the page-avail flag for the flipper */
	vqabuf->Flags |= VQADATF_UPDATE;

	/* Move to the next frame */
	drawer->CurFrame = curframe->Next;

	return (0);
}


/****************************************************************************
*
* NAME
*     DrawFrame_XmodeBuf - Draws a frame in Xmode format to a buffer.
*
* SYNOPSIS
*     Error = DrawFrame_XmodeBuf(VQA)
*
*     long DrawFrame_XmodeBuf(VQAHandle *);
*
* FUNCTION
*     Algorithm:
*       - Skip frames
*       - UnLCW frame
*       - Un-VQ into ImageBuf
*       - Copy ImageBuf to video RAM
*       - Wait on Update_Enabled
*       - Set the Flipper's CurFrame
*       - Set Update_Enabled
*       - Go to next frame
*	      - User_Update:
*         Flip X-Page
*         Set Palette from Flipper.CurFrame
*
*     This function implements a sort of cooperative multitasking.  If the
*     Drawer hits a "wait state", where it has to wait for Update_Enabled
*     to toggle, it sets a flag and returns.  This flag is checked on entry
*     to see if we need to jump to the proper execution point. This should
*     improve performance on some platforms.
*
*     This routine handles small images by UnVQ'ing into the upper-left
*     corner of ImageBuf, then copying ImageBuf into the correct part of the
*     Xmode screen.
*
* INPUTS
*     VQA - Pointer to VQAHandle.
*
* RESULT
*     Error - 0 if successful, or VQAERR_??? error code.
*
****************************************************************************/

static long DrawFrame_XmodeBuf(VQAHandle *vqa)
{
	VQAData       *vqabuf;
	VQADrawer     *drawer;
	VQAFrameNode  *curframe;
	VQAHeader     *header;
	VQAConfig     *config;
	unsigned char *scrn;
	long          rc;

	/* Dereference data members for quicker access */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	drawer = &vqabuf->Drawer;
	header = &((VQAHandleP *)vqa)->Header;
	config = &((VQAHandleP *)vqa)->Config;

	/* Check our "sleep" state */
	if (!(vqabuf->Flags & VQADATF_DSLEEP)) {

		/* Find the frame to draw */
		if ((rc = Select_Frame((VQAHandleP *)vqa)) != 0) {
			return (rc);
		}

		/* Uncompress the frame data */
		Prepare_Frame(vqabuf);

		/* Dereference current frame for quicker access. */
		curframe = drawer->CurFrame;

		/* Un-VQ the image */
		vqabuf->UnVQ(curframe->Codebook->Buffer, curframe->Pointers,
				drawer->ImageBuf, drawer->BlocksPerRow, drawer->NumRows,
				header->ImageWidth);

		/* Copy the buffer */
		scrn = GetXHidPage();

		if ((header->ImageWidth < 320) || (header->ImageHeight < 200)) {
			Xmode_Blit(drawer->ImageBuf, scrn + drawer->ScreenOffset,
					header->ImageWidth, header->ImageHeight);
		} else {
			Xmode_BufferCopy_320x200(drawer->ImageBuf,scrn + drawer->ScreenOffset);
		}

		/* Invoke user's callback routine */
		if (config->DrawerCallback != NULL) {
			if ((config->DrawerCallback(scrn, curframe->FrameNum)) != 0) {
				return (VQAERR_EOF);
			}
		}
	}

	/* Wait for Update_Enabled to be set low */
	if (vqabuf->Flags & VQADATF_UPDATE) {
		vqabuf->Flags |= VQADATF_DSLEEP;
		return (VQAERR_SLEEPING);
	}

	if (vqabuf->Flags & VQADATF_DSLEEP) {
		drawer->WaitsOnFlipper++;
		vqabuf->Flags &= (~VQADATF_DSLEEP);
	}

	/* Dereference current frame for quicker access. */
	curframe = drawer->CurFrame;

	/* Update data for mono output */
	drawer->LastFrameNum = curframe->FrameNum;

	/* Tell the flipper which frame to use */
	vqabuf->Flipper.CurFrame = curframe;

	/* Set the page-avail flag for the flipper */
	vqabuf->Flags |= VQADATF_UPDATE;

	/* Move to the next frame */
	drawer->CurFrame = curframe->Next;

	return (0);
}


/****************************************************************************
*
* NAME
*     DrawFrame_XmodeVRAM - Draws a frame in Xmode with resident Codebook.
*
* SYNOPSIS
*     Error = DrawFrame_XmodeVRAM(VQA)
*
*     long DrawFrame_XmodeVRAM(VQAHandle *);
*
* FUNCTION
*     Algorithm:
*       - Download Codebook if it isn't already (do this before skipping
*         frames, so Select_Frame will smooth out the delay)
*       - Skip frames
*       - UnLCW frame
*       - Convert Pointers to VRAM format
*       - Un-VQ by copying codebook blocks within VRAM
*       - Wait on Update_Enabled
*       - Set the Flipper's CurFrame
*       - Set Update_Enabled
*       - Go to next frame
*       - User_Update:
*         Flip X-Page
*         Set Palette from Flipper.CurFrame
*
*     This function implements a sort of cooperative multitasking.  If the
*     Drawer hits a "wait state", where it has to wait for Update_Enabled
*     to toggle, it sets a flag and returns.  This flag is checked on entry
*     to see if we need to jump to the proper execution point. This should
*     improve performance on some platforms.
*
*     This routine handles small images by UnVQ'ing into the correct spot on
*     the Xmode screen.
*
* INPUTS
*     VQA - Pointer to VQAHandle.
*
* RESULT
*     Error - 0 if successful, or VQAERR_??? error code.
*
****************************************************************************/

static long DrawFrame_XmodeVRAM(VQAHandle *vqa)
{
	VQAData       *vqabuf;
	VQADrawer     *drawer;
	VQAFrameNode  *curframe;
	VQAConfig     *config;
	unsigned char *scrn;
	long          rc;

	/* Dereference data members for quicker access */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	drawer = &vqabuf->Drawer;
	config = &((VQAHandleP *)vqa)->Config;

	/* Check our "sleep" state */
	if (!(vqabuf->Flags & VQADATF_DSLEEP)) {

		/* Find the frame to draw */
		if ((rc = Select_Frame((VQAHandleP *)vqa)) != 0) {
			return (rc);
		}

		/* Uncompress the frame data */
		Prepare_Frame(vqabuf);

		/* Dereference current frame for quicker access. */
		curframe = drawer->CurFrame;

		/* Download codebook to VRAM */
		if ((curframe->Codebook->Flags & VQACBF_DOWNLOADED) == 0) {
			Upload_4x2CB(curframe->Codebook->Buffer,
					((VQAHandleP *)vqa)->Header.CBentries
					+ ((VQAHandleP *)vqa)->Header.Num1Colors);

			curframe->Codebook->Flags |= VQACBF_DOWNLOADED;
		}

		/* Convert pointers to VRAM format */
		XlatePointers(curframe->Pointers, drawer->NumBlocks);

		/* Un-VQ the image */
		scrn = GetXHidPage();
		vqabuf->UnVQ(curframe->Codebook->Buffer, curframe->Pointers,
				scrn + drawer->ScreenOffset, drawer->BlocksPerRow,
				drawer->NumRows, 320);

		/* Invoke user's callback routine */
		if (config->DrawerCallback != NULL) {
			if ((config->DrawerCallback(scrn, curframe->FrameNum)) != 0) {
				return (VQAERR_EOF);
			}
		}
	}

	/* Wait for Update_Enabled to be set low */
	if (vqabuf->Flags & VQADATF_UPDATE) {
		vqabuf->Flags |= VQADATF_DSLEEP;
		return (VQAERR_SLEEPING);
	}

	if (vqabuf->Flags & VQADATF_DSLEEP) {
		drawer->WaitsOnFlipper++;
		vqabuf->Flags &= (~VQADATF_DSLEEP);
	}

	/* Dereference current frame for quicker access. */
	curframe = drawer->CurFrame;

	/* Update data for mono output */
	drawer->LastFrameNum = curframe->FrameNum;

	/* Tell the flipper which frame to use */
	vqabuf->Flipper.CurFrame = curframe;

	/* Set the page-avail flag for the flipper */
	vqabuf->Flags |= VQADATF_UPDATE;

	/* Move to the next frame */
	drawer->CurFrame = curframe->Next;

	return (0);
}


/****************************************************************************
*
* NAME
*     PageFlip_Xmode - Page flip Xmode display.
*
* SYNOPSIS
*     PageFlip_Xmode(VQA)
*
*     void PageFlip_Xmode(VQAHandle *);
*
* FUNCTION
*
* INPUTS
*     VQA - Pointer to VQAHandle.
*
* RESULT
*     NONE
*
****************************************************************************/

static void PageFlip_Xmode(VQAHandle *vqa)
{
	VQAData       *vqabuf;
	VQADrawer     *drawer;
	VQAFrameNode  *curframe;
	unsigned char *pal;
	VQAConfig     *config;
	long          palsize;
	long          slowpal;

	/* Dereference commonly used data members for quicker access. */
	config = &((VQAHandleP *)vqa)->Config;
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	drawer = &vqabuf->Drawer;
	curframe = vqabuf->Flipper.CurFrame;

	/* Pre-decode 'vqa' for speed */
	pal = curframe->Palette;
	palsize = curframe->PaletteSize;
	slowpal = (config->OptionFlags & VQAOPTF_SLOWPAL) ? 1 : 0;

	/* - If this is a palette-set frame:
	 * - Wait for NoVB (active scan)
	 * - Flip the page (doesn't take effect until next active scan
	 * - Wait for VB
	 * - Set the palette
	 * - Otherwise, just flip the page
	 */
	if (curframe->Flags & VQAFRMF_PALETTE) {
		WaitNoVB(vqabuf->VBIBit);
		FlipXPage();
		WaitVB(vqabuf->VBIBit);

		if (!(config->OptionFlags & VQAOPTF_PALOFF)) {
			SetPalette(pal, palsize, slowpal);
		}

		/* Notify the client of the palette change. */
		if ((config->NotifyFlags & VQAEVENT_PALETTE)
				&& (config->EventHandler != NULL)) {
			config->EventHandler(VQAEVENT_PALETTE, (void *)pal, (long)palsize);
		}
	}
	else if (drawer->Flags & VQADRWF_SETPAL) {
		drawer->Flags &= (~VQADRWF_SETPAL);
		WaitNoVB(vqabuf->VBIBit);
		FlipXPage();
		WaitVB(vqabuf->VBIBit);

		if (!(config->OptionFlags & VQAOPTF_PALOFF)) {
			SetPalette(drawer->Palette_24, drawer->CurPalSize, slowpal);
		}

		/* Notify the client of the palette change. */
		if ((config->NotifyFlags & VQAEVENT_PALETTE)
				&& (config->EventHandler != NULL)) {

			config->EventHandler(VQAEVENT_PALETTE, (void *)drawer->Palette_24,
					(long)drawer->CurPalSize);
		}
	} else {
		FlipXPage();
	}
}
#endif /* VQAXMODE_ON */


#if(VQAMCGA_ON)
/****************************************************************************
*
* NAME
*     DrawFrame_MCGA - Draws a frame directly to MCGA screen.
*
* SYNOPSIS
*     Error = DrawFrame_MCGA(VQA)
*
*     long DrawFrame_MCGA(VQAHandle *);
*
* FUNCTION
*     Algorithm:
*       - Skip frames
*       - UnLCW frame
*       - Wait on Update_Enabled
*       - Set Update_Enabled
*       - Go to next frame
*       - User_Update:
*         set palette
*         UnVQ to screen
*
*     This function implements a sort of cooperative multitasking.  If the
*     Drawer hits a "wait state", where it has to wait for Update_Enabled
*     to toggle, it sets a flag and returns.  This flag is checked on entry
*     to see if we need to jump to the proper execution point. This should
*     improve performance on some platforms.
*
*     This routine handles small images by UnVQ'ing into the correct spot on
*     the screen.
*
* INPUTS
*     VQA - Pointer to VQAHandle.
*
* RESULT
*     Error - 0 if successful, or VQAERR_??? error code.
*
****************************************************************************/

static long DrawFrame_MCGA(VQAHandle *vqa)
{
	VQAData      *vqabuf;
	VQADrawer    *drawer;
	VQAFrameNode *curframe;
	long         rc;

	/* Dereference commonly used data members for quicker access */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	drawer = &vqabuf->Drawer;

	/* Check our "sleep" state */
	if (!(vqabuf->Flags & VQADATF_DSLEEP)) {

		/* Select the frame to draw. */
		if ((rc = Select_Frame((VQAHandleP *)vqa)) != 0) {
			return (rc);
		}

		/* Uncompress the frame data */
		Prepare_Frame(vqabuf);
	}

	/* Wait for Update_Enabled to be set low */
	if (vqabuf->Flags & VQADATF_UPDATE) {
		vqabuf->Flags |= VQADATF_DSLEEP;
		return (VQAERR_SLEEPING);
	}

	if (vqabuf->Flags & VQADATF_DSLEEP) {
		drawer->WaitsOnFlipper++;
		vqabuf->Flags &= (~VQADATF_DSLEEP);
	}

	/* Dereference current frame for quicker access. */
	curframe = drawer->CurFrame;

	/* Update data for mono output */
	drawer->LastFrameNum = curframe->FrameNum;

	/* Tell the flipper which frame to use */
	vqabuf->Flipper.CurFrame = curframe;

	/* Set the page-avail flag for the flipper */
	vqabuf->Flags |= VQADATF_UPDATE;

	/* Move to the next frame */
	drawer->CurFrame = curframe->Next;

	return (0);
}


/****************************************************************************
*
* NAME
*     PageFlip_MCGA - Page flip MCGA display.
*
* SYNOPSIS
*     PageFlip_MCGA(VQA)
*
*     long PageFlip_MCGA(VQAHandle *);
*
* FUNCTION
*     Since the MCGA mode only has one buffer, the drawing is actually done
*     at this point.
*
* INPUTS
*     VQA - Pointer to VQAHandle structure.
*
* RESULT
*     Error - 0 if successfull, otherwise VQAERR_???
*
****************************************************************************/

static long PageFlip_MCGA(VQAHandle *vqa)
{
	VQAData       *vqabuf;
	VQADrawer     *drawer;
	VQAFrameNode  *curframe;
	VQAConfig     *config;
	unsigned char *pal;
	unsigned char *ptrs;
	unsigned char *cb;
	long          palsize;
	long          slowpal;
	long          blocksperrow;
	long          numrows;

	#ifndef PHARLAP_TNT
	unsigned char *scrn;
	#else
	FARPTR        scrn;
	#endif

	/* Dereference commonly used data members for quicker access. */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	config = &((VQAHandleP *)vqa)->Config;
	drawer = &vqabuf->Drawer;
	curframe = vqabuf->Flipper.CurFrame;

	/*-------------------------------------------------------------------------
	 * WAIT FOR THE VERTICAL BLANK TO SET THE PALETTE.
	 *-----------------------------------------------------------------------*/
	if ((curframe->Flags & VQAFRMF_PALETTE)
			|| (drawer->Flags & VQADRWF_SETPAL)) {

		pal = curframe->Palette;
		palsize = curframe->PaletteSize;
		slowpal = (config->OptionFlags & VQAOPTF_SLOWPAL) ? 1 : 0;

		/* Wait for the VBlank. */
	 	WaitNoVB(vqabuf->VBIBit);
	 	WaitVB(vqabuf->VBIBit);

		/* Set the palette. */
		if (curframe->Flags & VQAFRMF_PALETTE) {
			if (!(config->OptionFlags & VQAOPTF_PALOFF)) {
				SetPalette(pal, palsize, slowpal);
			}

			/* Notify the client of the palette change. */
			if ((config->NotifyFlags & VQAEVENT_PALETTE)
					&& (config->EventHandler != NULL)) {

				config->EventHandler(VQAEVENT_PALETTE, (void *)pal, (long)palsize);
			}
		}
		else if (drawer->Flags & VQADRWF_SETPAL) {
			drawer->Flags &= (~VQADRWF_SETPAL);

			if (!(config->OptionFlags & VQAOPTF_PALOFF)) {
				SetPalette(drawer->Palette_24, drawer->CurPalSize, slowpal);
			}

			/* Notify the client of the palette change. */
			if ((config->NotifyFlags & VQAEVENT_PALETTE)
					&& (config->EventHandler != NULL)) {

				config->EventHandler(VQAEVENT_PALETTE, (void *)drawer->Palette_24,
						(long)drawer->CurPalSize);
			}
		}
	}

	/*-------------------------------------------------------------------------
	 * UNVQ THE FRAME DIRECTLY TO THE MCGA SCREEN.
	 *-----------------------------------------------------------------------*/

	/* Get screen address, blocks per row and number of rows. */
	#ifndef PHARLAP_TNT
	scrn = (unsigned char *)(0xA0000 + (unsigned long)drawer->ScreenOffset);
	#else
	FP_SET(scrn, drawer->ScreenOffset, 0x1C);
	#endif

	blocksperrow = drawer->BlocksPerRow;
	numrows = drawer->NumRows;
	ptrs = curframe->Pointers;
	cb = curframe->Codebook->Buffer;
	vqabuf->UnVQ(cb, ptrs, scrn, blocksperrow, numrows, 320);

	#if(VQACAPTIONS_ON)
	/* Process captions. */
	if ((((VQAHandleP *)vqa)->Caption != NULL)
			&& (config->OptionFlags & VQAOPTF_CAPTIONS)) {
		DoCaptions(((VQAHandleP *)vqa)->Caption, curframe->FrameNum);
	}

	if ((((VQAHandleP *)vqa)->EVA != NULL)
			&& (config->OptionFlags & VQAOPTF_EVA)) {
		DoCaptions(((VQAHandleP *)vqa)->EVA, curframe->FrameNum);
	}

	#endif

	/* Invoke user's callback routine */
	if (config->DrawerCallback != NULL) {
		if ((config->DrawerCallback(NULL, curframe->FrameNum)) != 0) {
			return (VQAERR_EOF);
		}
	}

	return (0);
}


/****************************************************************************
*
* NAME
*     DrawFrame_MCGABuf - Draws a frame in MCGA format to a buffer.
*
* SYNOPSIS
*     Error = DrawFrame_MCGABuf(VQA)
*
*     long DrawFrame_MCGABuf(VQAHandle *);
*
* FUNCTION
*     Algorithm:
*       - Skip frames
*       - UnLCW frame
*       - Wait on Update_Enabled (can't use imgbuf til User_Update's done)
*       - Un-VQ into ImageBuf
*       - Set the Flipper's CurFrame
*       - Set Update_Enabled
*       - Go to next frame
*       - User_Update:
*         set Palette from Flipper.CurFrame
*         copy ImageBuf to screen
*
*     This function implements a sort of cooperative multitasking.  If the
*     Drawer hits a "wait state", where it has to wait for Update_Enabled
*     to toggle, it sets a flag and returns.  This flag is checked on entry
*     to see if we need to jump to the proper execution point. This should
*     improve performance on some platforms.
*
*     This routine handles small images by UnVQ'ing into the upper-left
*     corner of ImageBuf, then copying ImageBuf onto the screen.
*
* INPUTS
*     VQA - Pointer to VQAHandle.
*
* RESULT
*     Error - 0 if successful, or VQAERR_??? error code.
*
****************************************************************************/

static long DrawFrame_MCGABuf(VQAHandle *vqa)
{
	VQAData      *vqabuf;
	VQADrawer    *drawer;
	VQAFrameNode *curframe;
	long         rc;

	#ifndef PHARLAP_TNT
	unsigned char *scrn;
	#else
	FARPTR        scrn;
	#endif

	/* Dereference commonly used data members for quicker access. */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	drawer = &vqabuf->Drawer;

	/* Check our "sleep" state */
	if (!(vqabuf->Flags & VQADATF_DSLEEP)) {

		/* Find the frame to draw */
		if ((rc = Select_Frame((VQAHandleP *)vqa)) != 0) {
			return (rc);
		}

		/* Uncompress the frame data */
		Prepare_Frame(vqabuf);
	}

	/* Wait for Update_Enabled to be set low */
	if (vqabuf->Flags & VQADATF_UPDATE) {
		vqabuf->Flags |= VQADATF_DSLEEP;
		return (VQAERR_SLEEPING);
	}

	if (vqabuf->Flags & VQADATF_DSLEEP) {
		drawer->WaitsOnFlipper++;
		vqabuf->Flags &= (~VQADATF_DSLEEP);
	}

	/* Dereference current frame for quicker access. */
	curframe = drawer->CurFrame;

	#ifndef PHARLAP_TNT
	scrn = drawer->ImageBuf;
	#else
	FP_SET(scrn, drawer->ImageBuf, 0x14);
	#endif

	/* Un-VQ the image */
	vqabuf->UnVQ(curframe->Codebook->Buffer, curframe->Pointers, scrn,
			drawer->BlocksPerRow, drawer->NumRows,
			((VQAHandleP *)vqa)->Header.ImageWidth);

	/* Update data for mono output */
	drawer->LastFrameNum = curframe->FrameNum;

	/* Tell the flipper which frame to use */
	vqabuf->Flipper.CurFrame = curframe;

	/* Set the page-avail flag for the flipper */
	vqabuf->Flags |= VQADATF_UPDATE;

	/* Move to the next frame */
	drawer->CurFrame = curframe->Next;

	return (0);
}


/****************************************************************************
*
* NAME
*     PageFlip_MCGABuf - Page flip a buffered MCGA display.
*
* SYNOPSIS
*     PageFlip_MCGABuf(VQA)
*
*     void PageFlip_MCGABuf(VQAHandle *);
*
* FUNCTION
*
* INPUTS
*     VQA - Pointer to VQAHandle.
*
* RESULT
*     Error - 0 if successfull, otherwise VQAERR_???
*
****************************************************************************/

static long PageFlip_MCGABuf(VQAHandle *vqa)
{
	VQAData       *vqabuf;
	VQADrawer     *drawer;
	VQAFrameNode  *curframe;
	VQAConfig     *config;
	unsigned char *pal;
	unsigned char *buf;
	unsigned char *scrn;
	long          palsize;
	long          slowpal;
	long          imgwidth;
	long          imgheight;

	/* Derefernce commonly used data members for quicker access. */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	config = &((VQAHandleP *)vqa)->Config;
	drawer = &vqabuf->Drawer;
	curframe = vqabuf->Flipper.CurFrame;

	/* Pre-decode 'vqa' for speed */
	pal = curframe->Palette;
	palsize = curframe->PaletteSize;
	slowpal = (config->OptionFlags & VQAOPTF_SLOWPAL) ? 1 : 0;

	/* - If this is a palette-set frame:
	 * - Wait for the vertical blank
	 * - Set the palette
	 * - Copy ImageBuf to SEENPAGE:
	 * - use blit routine if image is smaller than full-screen, since the
	 *   buffer copy assumes a full-screen image
	 */
	if (curframe->Flags & VQAFRMF_PALETTE) {
		WaitNoVB(vqabuf->VBIBit);
		WaitVB(vqabuf->VBIBit);

		if (!(config->OptionFlags & VQAOPTF_PALOFF)) {
			SetPalette(pal, palsize, slowpal);
		}

		/* Notify the client of the palette change. */
		if ((config->NotifyFlags & VQAEVENT_PALETTE)
				&& (config->EventHandler != NULL)) {

			config->EventHandler(VQAEVENT_PALETTE, (void *)pal, (long)palsize);
		}
	}
	else if (drawer->Flags & VQADRWF_SETPAL) {
		drawer->Flags &= (~VQADRWF_SETPAL);
		WaitNoVB(vqabuf->VBIBit);
		WaitVB(vqabuf->VBIBit);

		if (!(config->OptionFlags & VQAOPTF_PALOFF)) {
			SetPalette(drawer->Palette_24, drawer->CurPalSize, slowpal);
		}

		/* Notify the client of the palette change. */
		if ((config->NotifyFlags & VQAEVENT_PALETTE)
				&& (config->EventHandler != NULL)) {

			config->EventHandler(VQAEVENT_PALETTE, (void *)drawer->Palette_24,
					(long)drawer->CurPalSize);
		}
	}

	/* Draw image to the screen. */
	imgwidth = ((VQAHandleP *)vqa)->Header.ImageWidth;
	imgheight = ((VQAHandleP *)vqa)->Header.ImageHeight;
	buf = drawer->ImageBuf;

	#ifndef PHARLAP_TNT
	scrn = (unsigned char *)0xA0000;
	#endif

	if ((imgwidth < 320) || (imgheight < 200)) {
		#ifndef PHARLAP_TNT
		scrn += drawer->ScreenOffset;
		#else
		scrn = (unsigned char *)drawer->ScreenOffset;
		#endif

		MCGA_Blit(buf, scrn, imgwidth, imgheight);
	} else {
		MCGA_BufferCopy(buf, NULL);
	}

	/* Invoke user's callback routine */
	if (config->DrawerCallback != NULL) {
		if ((config->DrawerCallback(NULL, curframe->FrameNum)) != 0) {
			return (VQAERR_EOF);
		}
	}

	return (0);
}
#endif /* VQAMCGA_ON */


#if(VQAVESA_ON)
/****************************************************************************
*
* NAME
*     DrawFrame_VESA640 - Draws a frame in VESA 640 format.
*
* SYNOPSIS
*     Error = DrawFrame_VESA640(VQA)
*
*     long DrawFrame_VESA640(VQAHandle *);
*
* FUNCTION
*
* INPUTS
*     VQA - Pointer to VQAHandle.
*
* RESULT
*     Error - 0 if successful, or VQAERR_??? error code.
*
****************************************************************************/

static long DrawFrame_VESA640(VQAHandle *vqa)
{
	VQAData      *vqabuf;
	VQADrawer    *drawer;
	VQAFrameNode *curframe;
	long         rc;

	#ifndef PHARLAP_TNT
	unsigned char *scrn;
	#else
	FARPTR        scrn;
	#endif

	/* Dereference data members for quicker access. */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	drawer = &vqabuf->Drawer;

	/* Check our "sleep" state */
	if (!(vqabuf->Flags & VQADATF_DSLEEP)) {

		/* Find the frame to draw */
		if ((rc = Select_Frame((VQAHandleP *)vqa)) != 0) {
			return (rc);
		}

		/* Uncompress the frame data */
		Prepare_Frame(vqabuf);
	}

	/* Dereference current frame. */
	curframe = drawer->CurFrame;

	/* Wait for Update_Enabled to be set low */
 	if (vqabuf->Flags & VQADATF_UPDATE) {
		vqabuf->Flags |= VQADATF_DSLEEP;
		return (VQAERR_SLEEPING);
	}

	if (vqabuf->Flags & VQADATF_DSLEEP) {
		vqabuf->Drawer.WaitsOnFlipper++;
		vqabuf->Flags &= (~VQADATF_DSLEEP);
	}

	#ifndef PHARLAP_TNT
	scrn = drawer->ImageBuf + drawer->ScreenOffset;
	#else
	FP_SET(scrn, drawer->ImageBuf + drawer->ScreenOffset, 0x14);
	#endif

	/* Un-VQ the image */
	vqabuf->UnVQ(curframe->Codebook->Buffer, curframe->Pointers, scrn,
			drawer->BlocksPerRow, drawer->NumRows, drawer->ImageWidth);

	/* Update data for mono output */
	drawer->LastFrameNum = curframe->FrameNum;

	/* Tell the flipper which frame to use */
	vqabuf->Flipper.CurFrame = curframe;

	/* Set the page-avail flag for the flipper */
	vqabuf->Flags |= VQADATF_UPDATE;

	/* Move to the next frame */
	drawer->CurFrame = curframe->Next;

	return (0);
}


/****************************************************************************
*
* NAME
*     DrawFrame_VESA320_32K - Draws a frame in VESA 320 format.
*
* SYNOPSIS
*     Error = DrawFrame_VESA320_32K(VQA)
*
*     long DrawFrame_VESA320_32K(VQAHandle *);
*
* FUNCTION
*
* INPUTS
*     VQA - Pointer to VQAHandle.
*
* RESULT
*     Error - 0 if successful, or VQAERR_??? error code.
*
****************************************************************************/

static long DrawFrame_VESA320_32K(VQAHandle *vqa)
{
	VQAData      *vqabuf;
	VQADrawer    *drawer;
	VQAFrameNode *curframe;
	VQAConfig    *config;
	long         rc;
	long         grain;

	/* Dereference data members for quicker access. */
	config = &((VQAHandleP *)vqa)->Config;
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	drawer = &vqabuf->Drawer;

	/* Check our "sleep" state */
	if (!(vqabuf->Flags & VQADATF_DSLEEP)) {

		/* Find the frame to draw */
		if ((rc = Select_Frame((VQAHandleP *)vqa)) != 0) {
			return (rc);
		}

		/* Uncompress the frame data */
		Prepare_Frame(vqabuf);

		/* Dereference current frame. */
		curframe = drawer->CurFrame;

		/* Translate palette to 15-bit */
		if (curframe->Flags & VQAFRMF_PALETTE) {
			TranslatePalette(curframe->Palette, drawer->Palette_15,
					curframe->PaletteSize);
		}
		else if (drawer->Flags & VQADRWF_SETPAL) {
			TranslatePalette(drawer->Palette_24, drawer->Palette_15,
					drawer->CurPalSize);
		}

		/* UnVQ directly to screen */
		grain = ((VESAModeInfo *)(drawer->Display->Extended))->WinSize
				/ ((VESAModeInfo *)(drawer->Display->Extended))->WinGranularity;

		#ifndef PHARLAP_TNT
		vqabuf->UnVQ(curframe->Codebook->Buffer, curframe->Pointers,
				drawer->Palette_15, grain, 0, 0);
		#else
		{
		FARPTR temp;

		FP_SET(temp, drawer->Palette_15, 0x14);

		vqabuf->UnVQ(curframe->Codebook->Buffer, curframe->Pointers, temp,
				grain, 0, 0);
		}
		#endif

		/* Invoke user's callback routine */
		if (config->DrawerCallback != NULL) {
			if ((config->DrawerCallback(0, curframe->FrameNum)) != 0) {
				return (VQAERR_EOF);
			}
		}
	}

	/* Wait for VQ_Update_Enabled to be set low */
	if (vqabuf->Flags & VQADATF_UPDATE) {
		vqabuf->Flags |= VQADATF_DSLEEP;
		return (VQAERR_SLEEPING);
	}

	if (vqabuf->Flags & VQADATF_DSLEEP) {
		drawer->WaitsOnFlipper++;
		vqabuf->Flags &= (~VQADATF_DSLEEP);
	}

	/* Update data for mono output */
	drawer->LastFrameNum = curframe->FrameNum;

	/* Tell the flipper which frame to use */
	vqabuf->Flipper.CurFrame = curframe;

	/* Set the page-avail flag for the flipper */
	vqabuf->Flags |= VQADATF_UPDATE;

	/* Move to the next frame */
	drawer->CurFrame = curframe->Next;

	return (0);
}


/****************************************************************************
*
* NAME
*     DrawFrame_VESA320_32KBuf - Draws a frame in VESA320_32K format to a
*                                buffer.
*
* SYNOPSIS
*     Error = DrawFrame_VESA320_32KBuf(VQA)
*
*     long DrawFrame_VESA320_32KBuf(VQAHandle *);
*
* FUNCTION
*
* INPUTS
*     VQA - Pointer to VQAHandle.
*
* RESULT
*     Error - 0 if successful, or VQAERR_??? error code.
*
****************************************************************************/

static long DrawFrame_VESA320_32KBuf(VQAHandle *vqa)
{
	VQAData      *vqabuf;
	VQADrawer    *drawer;
	VQAFrameNode *curframe;
	VQAConfig    *config;
	long         rc;
	long         grain;

	/* Dereference data members for quicker access. */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	config = &((VQAHandleP *)vqa)->Config;
	drawer = &vqabuf->Drawer;
	curframe = drawer->CurFrame;

	/* Check our "sleep" state */
	if (!(vqabuf->Flags & VQADATF_DSLEEP)) {

		/* Find the frame to draw */
		if ((rc = Select_Frame((VQAHandleP *)vqa)) != 0) {
			return (rc);
		}

		/* Uncompress the frame data */
		Prepare_Frame(vqabuf);

		/* UnVQ buffered mode */
		#ifndef PHARLAP_TNT
		vqabuf->UnVQ(curframe->Codebook->Buffer, curframe->Pointers,
				drawer->ImageBuf, drawer->BlocksPerRow, drawer->NumRows,
				((VQAHandleP *)vqa)->Header.image_width);
		#else
		{
		FARPTR scrn;

		FP_SET(scrn, drawer->ImageBuf, 0x14);

		vqabuf->UnVQ(curframe->Codebook->Buffer, curframe->Pointers, scrn,
				drawer->BlocksPerRow, drawer->NumRows,
				((VQAHandleP *)vqa)->Header.image_width);
		}
		#endif

		/* Translate the palette to 15-bit */
		if (curframe->Flags & VQAFRMF_PALETTE) {
			TranslatePalette(curframe->Palette, drawer->Palette_15,
					curframe->PaletteSize);
		}
		else if (drawer->Flags & VQADRWF_SETPAL) {
			TranslatePalette(drawer->Palette_24, drawer->Palette_15,
					drawer->CurPalSize);
		}

		/* Copy the buffer */
		grain = ((VESAModeInfo *)(drawer->Display->Extended))->WinSize
				/ ((VESAModeInfo *)(drawer->Display->Extended))->WinGranularity;

		Buf_320x200_To_VESA_32K(drawer->ImageBuf, drawer->Palette_15, grain);

 		/* Invoke user's callback routine */
		if (config->DrawerCallback != NULL) {
			if ((config->DrawerCallback(0, curframe->FrameNum)) != 0) {
				return (VQAERR_EOF);
			}
		}
	}

	/* Wait for Update_Enabled to be set low */
	if (vqabuf->Flags & VQADATF_UPDATE) {
		vqabuf->Flags |= VQADATF_DSLEEP;
		return (VQAERR_SLEEPING);
	}

	if (vqabuf->Flags & VQADATF_DSLEEP) {
		vqabuf->Flags &= (~VQADATF_DSLEEP);
		drawer->WaitsOnFlipper++;
	}

	/* Update data for mono output */
	drawer->LastFrameNum = curframe->FrameNum;

	/* Tell the flipper which frame to use */
	vqabuf->Flipper.CurFrame = curframe;

	/* Set the page-avail flag for the flipper */
	vqabuf->Flags |= VQADATF_UPDATE;

	/* Move to the next frame */
	drawer->CurFrame = curframe->Next;

	return (0);
}


/****************************************************************************
*
* NAME
*     PageFlip_VESA - Page flip VESA display.
*
* SYNOPSIS
*     PageFlip_VESA(VQA)
*
*     void PageFlip_VESA(VQAHandle *);
*
* FUNCTION
*
* INPUTS
*     VQA - Pointer to VQAHandle.
*
* RESULT
*     NONE
*
****************************************************************************/

static void PageFlip_VESA(VQAHandle *vqa)
{
	VQAData       *vqabuf;
	VQADrawer     *drawer;
	VQAFrameNode  *curframe;
	VQAConfig     *config;
	unsigned char *pal;
	long          palsize;
	long          slowpal;
	long          grain;

	/* Dereference date members for quicker access. */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	config = &((VQAHandleP *)vqa)->Config;
	drawer = &vqabuf->Drawer;
	curframe = vqabuf->Flipper.CurFrame;

	/* Pre-decode 'vqa' for speed */
	pal = curframe->Palette;
	palsize = curframe->PaletteSize;
	slowpal = (config->OptionFlags & VQAOPTF_SLOWPAL) ? 1 : 0;

	/* Set the palette */
	if (curframe->Flags & VQAFRMF_PALETTE) {
		WaitNoVB(vqabuf->VBIBit);
		WaitVB(vqabuf->VBIBit);

		if (!(config->OptionFlags & VQAOPTF_PALOFF)) {
			SetPalette(pal, palsize, slowpal);
		}

		/* Notify the client of the palette change. */
		if ((config->NotifyFlags & VQAEVENT_PALETTE)
				&& (config->EventHandler != NULL)) {

			config->EventHandler(VQAEVENT_PALETTE, (void *)pal, (long)palsize);
		}
	}
	else if (drawer->Flags & VQADRWF_SETPAL) {
		drawer->Flags &= (~VQADRWF_SETPAL);
		WaitNoVB(vqabuf->VBIBit);
		WaitVB(vqabuf->VBIBit);

		if (!(config->OptionFlags & VQAOPTF_PALOFF)) {
			SetPalette(drawer->Palette_24, drawer->CurPalSize, slowpal);
		}

		/* Notify the client of the palette change. */
		if ((config->NotifyFlags & VQAEVENT_PALETTE)
				&& (config->EventHandler != NULL)) {

			config->EventHandler(VQAEVENT_PALETTE, (void *)drawer->Palette_24,
					(long)drawer->CurPalSize);
		}
	}

	/* Copy the buffer */
	grain = ((VESAModeInfo *)(drawer->Display->Extended))->WinSize
			/ ((VESAModeInfo *)(drawer->Display->Extended))->WinGranularity;

	switch (((VQAHandleP *)vqa)->Header.image_width) {
		case 320:
			if (config->DrawFlags & VQACFGF_SCALEX2) {
				Buf_320x200_To_VESA_640x400(drawer->ImageBuf, grain);
			} else {
				Buf_320x200_To_VESA_320x200(drawer->ImageBuf, grain);
			}
			break;

		default:
			VESA_Blit_640x480(drawer->Display, drawer->ImageBuf, drawer->X1,
					drawer->Y1, ((VQAHandleP *)vqa)->Header.image_width,
					((VQAHandleP *)vqa)->Header.image_height);
			break;
	}

	/* Invoke user's callback routine */
	if (config->DrawerCallback != NULL) {
		if ((config->DrawerCallback(drawer->ImageBuf, curframe->FrameNum)) != 0) {
			return (VQAERR_EOF);
		}
	}
}
#endif /* VQAVESA_ON */


/****************************************************************************
*
* NAME
*     DrawFrame_Buffer - Draw a frame to a buffer.
*
* SYNOPSIS
*     Error = DrawFrame_Buffer(VQA)
*
*     long DrawFrame_Buffere(VQAHandle *);
*
* FUNCTION
*
* INPUTS
*     VQA - Pointer to VQA handle.
*
* RESULT
*     Error - 0 if successful, otherwise VQAERR_??? error code.
*
****************************************************************************/

extern void __cdecl Set_Palette(void *palette);
extern void Flag_To_Set_Palette(unsigned char *palette,long numbytes,unsigned long slowpal);
static long DrawFrame_Buffer(VQAHandle *vqa)
{
	VQAData      *vqabuf;
	VQADrawer    *drawer;
	VQAFrameNode *curframe;
	VQAConfig    *config;
	long         rc;
	unsigned char *pal;
	long          palsize;
	long          slowpal;

	#ifndef PHARLAP_TNT
	unsigned char *buff;
	#else
	FARPTR        buff;
	#endif

	/* Dereference data members for quicker access. */
	config = &((VQAHandleP *)vqa)->Config;
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	drawer = &vqabuf->Drawer;

	/* Check our "sleep" state */
	if (!(vqabuf->Flags & VQADATF_DSLEEP)) {

		/* Find the frame to draw */
		if ((rc = Select_Frame((VQAHandleP *)vqa)) != 0) {
			return (rc);
		}

		/* Uncompress the frame data */
		Prepare_Frame(vqabuf);
	}

	/* Wait for Update_Enabled to be set low */
	if (vqabuf->Flags & VQADATF_UPDATE) {
		vqabuf->Flags |= VQADATF_DSLEEP;
		return (VQAERR_SLEEPING);
	}

	if (vqabuf->Flags & VQADATF_DSLEEP) {
		drawer->WaitsOnFlipper++;
		vqabuf->Flags &= (~VQADATF_DSLEEP);
	}

	/* Dereference current frame for quicker access. */
	curframe = drawer->CurFrame;

	#ifndef PHARLAP_TNT
	buff = (unsigned char *)(drawer->ImageBuf + drawer->ScreenOffset);
	#else
	FP_SET(buff, drawer->ImageBuf + drawer->ScreenOffset, 0x14);
	#endif


	pal = curframe->Palette;
	palsize = curframe->PaletteSize;
	slowpal = (config->OptionFlags & VQAOPTF_SLOWPAL) ? 1 : 0;

	/* Set the palette if neccessary */
	if ((curframe->Flags & VQAFRMF_PALETTE)
			|| (drawer->Flags & VQADRWF_SETPAL)) {
		Flag_To_Set_Palette(pal, palsize, slowpal);
		curframe->Flags &= ~VQAFRMF_PALETTE;
		drawer->Flags &= ~VQADRWF_SETPAL;
 	}


	/* Un-VQ the image */
	vqabuf->UnVQ(curframe->Codebook->Buffer, curframe->Pointers, buff,
			drawer->BlocksPerRow, drawer->NumRows, drawer->ImageWidth);

	/* Update data for mono output */
	drawer->LastFrameNum = curframe->FrameNum;

	/* Tell the flipper which frame to use */
	vqabuf->Flipper.CurFrame = curframe;

	/* Set the page-avail flag for the flipper */
	vqabuf->Flags |= VQADATF_UPDATE;

	/* Invoke user's callback routine */
	if (config->DrawerCallback != NULL) {
		if ((config->DrawerCallback(drawer->ImageBuf, curframe->FrameNum)) != 0) {
			return (VQAERR_EOF);
		}
	}

	/* Move to the next frame */
	drawer->CurFrame = curframe->Next;

	return (0);
}


/****************************************************************************
*
* NAME
*     UnVQ_Nop - Do nothing UnVQ.
*
* SYNOPSIS
*     UnVQ_Nop(Codebook, Pointers, Buffer, BPR, Rows, BufWidth)
*
*     void UnVQ_Nop(unsigned char *, unsigned char *, unsigned char *,
*                   unsigned long, unsigned long, unsigned long);
* FUNCTION
*
* INPUTS
*     Codebook - Not used. (Prototype placeholder)
*     Pointers - Not used. (Prototype placeholder)
*     Buffer   - Not used. (Prototype placeholder)
*     BPR      - Not used. (Prototype placeholder)
*     Rows     - Not used. (Prototype placeholder)
*     BufWidth - Not used. (Prototype placeholder)
*
* RESULT
*     NONE
*
****************************************************************************/

#ifndef PHARLAP_TNT
static void __cdecl UnVQ_Nop(unsigned char *codebook, unsigned char *pointers,
		unsigned char *buffer, unsigned long blocksperrow,
		unsigned long numrows, unsigned long bufwidth)
#else
static void __cdecl UnVQ_Nop(unsigned char *codebook, unsigned char *pointers,
		FARPTR buffer, unsigned long blocksperrow, unsigned long numrows,
		unsigned long bufwidth)
#endif
{
	/* Suppress compiler warnings */
	codebook = codebook;
	pointers = pointers;
	buffer = buffer;
	blocksperrow = blocksperrow;
	numrows = numrows;
	bufwidth = bufwidth;
}


/****************************************************************************
*
* NAME
*     PageFlip_Nop - Do nothing page flip.
*
* SYNOPSIS
*     PageFlip_Nop(VQA)
*
*     void PageFlip_Nop(VQAHandle *);
*
* FUNCTION
*
* INPUTS
*     VQA - Pointer to VQA handle.
*
* RESULT
*     NONE
*
****************************************************************************/

static long PageFlip_Nop(VQAHandle *vqa)
{
	vqa = vqa;

	return (0);
}


#if(0)
/****************************************************************************
*
* NAME
*     Mask_Rect - Sets non-drawable rectangle in image.
*
* SYNOPSIS
*     Mask_Rect(VQA, X1, Y1, X2, Y2)
*
*     void Mask_Rect(VQAHandle *, unsigned long, unsigned long,
*                    unsigned long, unsigned long);
*
* FUNCTION
*
* INPUTS
*     VQA - Pointer to VQA handle.
*     X1  - X coordinate of upper-left corner
*     Y1  - Y coordinate of upper-left corner
*     X2  - X coordinate of lower-right corner
*     Y2  - Y coordinate of lower-right corner
*
* RESULT
*     NONE
*
****************************************************************************/

static void Mask_Rect(VQAHandle *vqa, unsigned long x1, unsigned long y1,
		unsigned long x2, unsigned long y2)
{
	VQAData   *vqabuf;
	VQADrawer *drawer;
	VQAHeader *header;
	long      blocks_per_row;

	/* Dereference data members for quicker access. */
	vqabuf = ((VQAHandleP *)vqa)->VQABuf;
	header = &((VQAHandleP *)vqa)->Header;
	drawer =  &vqabuf->Drawer;

	/* Clip coords to image size */
	if (x1 < vqabuf->Drawer.X1) {
		x1 = vqabuf->Drawer.X1;
	}

	if (y1 < vqabuf->Drawer.Y1) {
		y1 = vqabuf->Drawer.Y1;
	}

	if (x2 > vqabuf->Drawer.X2) {
		x2 = vqabuf->Drawer.X2;
	}

	if (y2 > vqabuf->Drawer.Y2) {
		y2 = vqabuf->Drawer.Y2;
	}

	/* Convert pixel coords to block coords */
	x1 /= header->block_width;
	x2 /= header->block_width;
	y1 /= header->block_height;
	y2 /= header->block_height;

	/* Compute the mask values */
	blocks_per_row = (header->image_width / header->block_width);
	vqabuf->Drawer.MaskStart = blocks_per_row * y1 + x1;

	if (x1 == x2) {
		drawer->MaskWidth = 0;
	} else {
		drawer->MaskWidth = x2 - x1 + 1;
	}

	if (y1 == y2) {
		drawer->MaskHeight = 0;
	} else {
		drawer->MaskHeight = y2 - y1 + 1;
	}
}


/****************************************************************************
*
* NAME
*     Mask_Pointers - Mask vector pointer that are in the mask rectangle.
*
* SYNOPSIS
*     Mask_Pointers(VQAData)
*
*     void Mask_Pointers(VQAData *);
*
* FUNCTION
*
* INPUTS
*     VQAData - Pointer to VQAData structure.
*
* RESULT
*     NONE
*
****************************************************************************/

static void Mask_Pointers(VQAData *vqabuf)
{
	VQADrawer     *drawer;
	VQAFrameNode  *curframe;
	unsigned long *ptr;
	unsigned long i,j;
	unsigned long start;

	/* Dereference data members for quicker access. */
	drawer = &vqabuf->Drawer;
	curframe = drawer->CurFrame;
	start = vqabuf->Drawer.MaskStart;

	for (i = 0; i < drawer->MaskHeight; i++) {
		ptr = (unsigned long *)(curframe->Pointers) + start;

		for (j = 0; j < drawer->MaskWidth; j++) {
			ptr[j] = VQA_MASK_POINTER;
		}

		start += drawer->BlocksPerRow;
	}
}
#endif

