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

#ifndef VQACAPTION_H
#define VQACAPTION_H
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
*     caption.h
*
* DESCRIPTION
*     Text caption definitions.
*
* PROGRAMMER
*     Denzil E. Long, Jr.
*
* DATE
*     July 26, 1995
*
****************************************************************************/


#define VQACAPTIONS_ON		0

/*---------------------------------------------------------------------------
 * STRUCTURES AND RELATED DEFINITIONS
 *-------------------------------------------------------------------------*/

/* CaptionNode: Node describing a caption to process.
 *
 * Succ    - Pointer to the next node in the list (successor).
 * Pred    - Pointer to the previous node in the list (predecessor).
 * Flags   - Status flags.
 * CapText - Pointer to the CaptionText being processed.
 * Char    - Pointer to current character in the string.
 * CurX    - Current X position.
 * CurY    - Current Y position.
 * BoundW  - Bounding width of text.
 * BoundH  - Bounding height of text.
 */
typedef struct _CaptionNode {
	struct _CaptionNode *Succ;
	struct _CaptionNode *Pred;
	unsigned short      Flags;
	CaptionText         *Captext;
	char                *Char;
	unsigned short      CurX;
	unsigned short      CurY;
	unsigned short      BoundW;
	unsigned short      BoundH;
} CaptionNode;

/* CaptionNode flag definitions. */
#define CNB_USED 0  /* This node is being used. */
#define CNF_USED (1<<CNB_USED)


/* CaptionList: Double linked list of outstanding captions to process.
 *
 * Head     - Pointer to the first node in the list.
 * Tail     - Always NULL
 * TailPred - Pointer to the last node in the list.
 */
typedef struct _CaptionList {
	CaptionNode *Head;
	CaptionNode *Tail;
	CaptionNode *TailPred;
} CaptionList;


/* CaptionInfo:
 *
 * Next   - Pointer to the next caption to be processed.
 * List   - List of pending captions to process.
 * Font   - Font to use for this caption.
 * BoundX - X position of bounding box.
 * BoundY - Y position of bounding box.
 * BoundW - Width of bounding box.
 * BoundH - Height of bounding box.
 * Buffer - Caption chunk buffer.
 */
typedef struct _CaptionInfo {
	CaptionText    *Next;
	CaptionList    List;
	void           *Font;
	char           FontHeight;
	char           FontWidth;
	void           *Buffer;
} CaptionInfo;


/*---------------------------------------------------------------------------
 * FUNCTION PROTOTYPES
 *-------------------------------------------------------------------------*/

CaptionInfo *OpenCaptions(void *captions, void *font);
void CloseCaptions(CaptionInfo *cap);
void DoCaptions(CaptionInfo *cap, unsigned long frame);

#endif /* VQACAPTION_H */

