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
*         C O N F I D E N T I A L -- W E S T W O O D  S T U D I O S
*
*----------------------------------------------------------------------------
*
* PROJECT
*     VQA player library (32 bit protected mode)
*
* FILE
*     caption.c
*
* DESCRIPTION
*     Text caption process/display manager.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     July 26, 1995
*
****************************************************************************/

#include <mem.h>
#include <malloc.h>
#include <vqm32\font.h>
#include <vqm32\text.h>
#include <vqm32\graphics.h>
#include <vqm32\captoken.h>
#include "caption.h"

#if( VQACAPTIONS_ON )


/*---------------------------------------------------------------------------
 * PRIVATE DECLARATIONS
 *-------------------------------------------------------------------------*/

#define NUM_NODES 3

/* Function prototypes. */
static CaptionNode *AddCaptionNode(CaptionList *list, CaptionText *captext);
static void RemCaptionNode(CaptionList *list, CaptionNode *node);


/****************************************************************************
*
* NAME
*     OpenCaptions - Initialize the caption system.
*
* SYNOPSIS
*     OpenCaptions(Captions, Font)
*
*     CaptionInfo *OpenCaptions(void *, void *);
*
* FUNCTION
*     Allocate and initialize resources used by the caption system.
*
* INPUTS
*     Captions - Captions to process.
*     Font     - Font to use to display captions.
*
* RESULT
*     CaptionInfo - Caption information structure.
*
* SEE ALSO
*     CloseCaption
*
****************************************************************************/

CaptionInfo *OpenCaptions(void *captions, void *font)
{
	CaptionInfo *cap = NULL;
	CaptionNode *node;
	FontInfo    *fi;
	long        i;

	/* Allocate memory for the captioning system. */
	cap = (CaptionInfo *)malloc(sizeof(CaptionInfo) + (sizeof(CaptionNode)
			* NUM_NODES));

	if (cap != NULL) {
		memset(cap,0,(sizeof(CaptionInfo) + (sizeof(CaptionNode) * NUM_NODES)));
		cap->Buffer = captions;
		cap->Next = (CaptionText *)captions;

		/* Initialize font */
		fi = (FontInfo *)((char *)font + ((Font *)font)->InfoBlk);
		cap->Font = font;
		cap->FontHeight = fi->MaxHeight;
		cap->FontWidth = fi->MaxWidth;

		/* Initialize list header. */
		cap->List.Head = (CaptionNode *)&cap->List.Tail;
		cap->List.Tail = NULL;
		cap->List.TailPred = (CaptionNode *)&cap->List.Head;

		/* Link nodes. */
		node = (CaptionNode *)((char *)cap + sizeof(CaptionInfo));

		for (i = 0; i < NUM_NODES; i++) {
			node->Succ = cap->List.Head;
			cap->List.Head = node;
			node->Pred = (CaptionNode *)&cap->List.Head;
			node->Succ->Pred = node;

			/* Next node. */
			node = (CaptionNode *)((char *)node + sizeof(CaptionNode));
		}
	}

	return (cap);
}


/****************************************************************************
*
* NAME
*     CloseCaptions - Shutdown the caption system.
*
* SYNOPSIS
*     CloseCaptions(CaptionInfo)
*
*     void CloseCaptions(CaptionInfo *);
*
* FUNCTION
*     Free the resources allocated by the caption system.
*
* INPUTS
*     CaptionInfo - Caption information structure.
*
* RESULT
*     NONE
*
* SEE ALSO
*     OpenCaptions
*
****************************************************************************/

void CloseCaptions(CaptionInfo *cap)
{
	free(cap);
}


/****************************************************************************
*
* NAME
*     DoCaption - Process and display caption text.
*
* SYNOPSIS
*     DoCaption(Captions, Frame)
*
*     void DoCaption(CaptionInfo *, unsigned long);
*
* FUNCTION
*     Process the caption events.
*
* INPUTS
*     Captions - Pointer to CaptionInfo structure.
*     Frame    - Current frame number being processed.
*
* RESULT
*     NONE
*
****************************************************************************/

void DoCaptions(CaptionInfo *cap, unsigned long frame)
{
	CaptionText *captext;
	CaptionNode *node;
	void const  *oldfont;
	long        width;
	long        i;

	/* Initialize variables. */
	oldfont = Set_Font((char *)cap->Font);

	/*-------------------------------------------------------------------------
	 * Process the captions that are on the active queue.
	 *-----------------------------------------------------------------------*/
	node = cap->List.Head;

	while ((node->Succ != NULL) && (node->Flags & CNF_USED)) {
		captext = node->Captext;

		/* Clear the any previous captions that have expired. */
		if (captext->OffFrame <= frame) {
			Fill_Rect(captext->Xpos, captext->Ypos,
					(captext->Xpos + node->BoundW - 1),
					(captext->Ypos + node->BoundH - 1), 0);

			/* Remove the caption from the active list. */
			node = node->Pred;
			RemCaptionNode(&cap->List, node->Succ);
		} else {
			if (captext->CPF != 0) {

				/* If a NULL terminator is not found then display the next set of
				 * characters, otherwise remove the node.
				 */
				if (*node->Char != 0) {
					Set_Font_Palette_Range(&captext->BgPen, 0, 1);

					for (i = 0; i < captext->CPF; i++) {

						/* Check for terminator. */
						if (*node->Char == 0) {
							captext->CPF = 0;
							break;
						}
						/* Check for newline. */
						else if (*node->Char == 0x0D) {
							node->Char++;
							node->CurX = captext->Xpos;
							node->CurY += cap->FontHeight;
							node->BoundH += cap->FontHeight;
						}

						Draw_Char(*node->Char, node->CurX, node->CurY);
						node->CurX += Char_Pixel_Width(*node->Char);
						node->Char++;
					}
				}
			} else if (captext->Flags & CTF_FLASH) {
				if (frame & 4) {
					Fill_Rect(captext->Xpos, captext->Ypos,
							(captext->Xpos + node->BoundW - 1),
							(captext->Ypos + node->BoundH - 1), 0);
				} else {
			 		Text_Print(captext->Text, captext->Xpos, captext->Ypos,
							captext->FgPen, captext->BgPen);
				}
			}
		}

		/* Next node. */
		node = node->Succ;
	}

	/*-------------------------------------------------------------------------
	 * Process any captions that are waiting to be activated.
	 *-----------------------------------------------------------------------*/
	captext = cap->Next;

	while (captext->OnFrame <= frame) {

		width = String_Pixel_Width(captext->Text);

		switch (captext->Flags & CTF_JUSTIFY) {
			case CTF_RIGHT:
				captext->Xpos = (319 - width);
				break;

			case CTF_LEFT:
				captext->Xpos = 0;
				break;

			case CTF_CENTER:
				captext->Xpos = (160 - (width / 2));
				break;

			default:
				break;
		}

		/* Display the text and record its bounding box. */
		if (captext->CPF == 0) {
	 		i = Text_Print(captext->Text, captext->Xpos, captext->Ypos,
					captext->FgPen, captext->BgPen);

			node = AddCaptionNode(&cap->List, captext);
			node->BoundW = width;
			node->BoundH = (cap->FontHeight * i);
		} else {
			node = AddCaptionNode(&cap->List, captext);
			node->BoundW = width;
			node->BoundH = cap->FontHeight;
		}

		/* Next */
		cap->Next = (CaptionText *)(((char *)captext) + captext->Size);
		captext = cap->Next;
	}

	Set_Font(oldfont);
}


/****************************************************************************
*
* NAME
*     AddCaptionNode - Add a caption to the processing list.
*
* SYNOPSIS
*     Node = AddCaptionNode(List, Caption)
*
*     CaptionNode *AddCaptionNode(CaptionList *, CaptionText *);
*
* FUNCTION
*     Add a caption the caption processing list.
*
* INPUTS
*     List    - Caption processing list.
*     Caption - Caption to add to the list.
*
* RESULT
*     Node - Pointer to node, otherwise NULL if error.
*
****************************************************************************/

static CaptionNode *AddCaptionNode(CaptionList *list, CaptionText *captext)
{
	CaptionNode *node = NULL;

	/* If this list is not full. */
	node = list->TailPred;

	if (!(node->Flags & CNF_USED)) {

		/* Remove the node from the tail. */
		node->Pred->Succ = node->Succ;
		list->TailPred = node->Pred;

		node->Flags |= CNF_USED;
		node->Captext = captext;
		node->Char = captext->Text;
		node->CurX = captext->Xpos;
		node->CurY = captext->Ypos;
		
		/* Add the node to the head. */
		node->Succ = list->Head;
		list->Head = node;
		node->Pred = (CaptionNode *)&list->Head;
		node->Succ->Pred = node;
	}

	return (node);
}


/****************************************************************************
*
* NAME
*     RemCaptionNode - Remove a caption from the processing list.
*
* SYNOPSIS
*     RemCaptionNode(List, Node)
*
*     void RemCaptionNode(CaptionList *, CaptionNode *);
*
* FUNCTION
*     Remove the caption from the processing list. Mark the node as unused
*     and put it at the tail of the list.
*
* INPUTS
*     List - Caption processing list.
*     Node - Caption node to remove.
*
* RESULT
*     NONE
*
****************************************************************************/

static void RemCaptionNode(CaptionList *list, CaptionNode *node)
{
	/* If the nodes successor is null then we are at the tail. */
	if (node->Succ != NULL) {

		/* Mark the node as unused. */
		node->Flags = 0;

		/* Relink the node to the tail. */
		node->Succ->Pred = node->Pred;
		node->Pred->Succ = node->Succ;
		node->Succ = (CaptionNode *)&list->Tail;
		node->Pred = list->TailPred;
		list->TailPred->Succ = node;
		list->TailPred = node;
	}
}


#endif // VQACAPTIONS_ON
