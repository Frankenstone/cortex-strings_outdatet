/*
 * strchr/strchrnul - find a character in a string
 *
 * Copyright (c) 2018, Linaro Limited
 * All rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the company nor the names of its contributors
 *       may be used to endorse or promote products derived from this
 *       software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* Assumptions:
 *
 * ARMv8-a, AArch64
 * SVE Available.
 */

	.arch	armv8-a+sve
	.text

/* To build as strchrnul, define BUILD_STPCPY before compiling this file.  */
#ifdef BUILD_STRCHRNUL
#define FUNC  strchrnul
#else
#define FUNC  strchr
#endif

	.globl	FUNC
	.type	FUNC, %function
	.p2align 4
FUNC:
	dup	z1.b, w1		/* replicate byte across vector */
	setffr				/* initialize FFR */
	ptrue	p1.b			/* all ones; loop invariant */

	.p2align 4
	/* Read a vector's worth of bytes, stopping on first fault.  */
0:	ldff1b	z0.b, p1/z, [x0, xzr]
	rdffrs	p0.b, p1/z
	b.nlast	2f

	/* First fault did not fail: the whole vector is valid.
	   Avoid depending on the contents of FFR beyond the branch.  */
	incb	x0				/* speculate increment */
	cmpeq	p2.b, p1/z, z0.b, z1.b		/* search for c */
	cmpeq	p3.b, p1/z, z0.b, 0		/* search for 0 */
	orrs	p4.b, p1/z, p2.b, p3.b		/* c | 0 */
	b.none	0b
	decb	x0				/* undo speculate */

	/* Found C or 0.  */
1:	brka	p4.b, p1/z, p4.b	/* find first such */
	sub	x0, x0, 1		/* adjust pointer for that byte */
	incp	x0, p4.b
#ifndef BUILD_STRCHRNUL
	ptest	p4, p2.b		/* was first in c? */
	csel	x0, xzr, x0, none	/* if there was no c, return null */
#endif
	ret

	/* First fault failed: only some of the vector is valid.
	   Perform the comparision only on the valid bytes.  */
2:	cmpeq	p2.b, p0/z, z0.b, z1.b		/* search for c */
	cmpeq	p3.b, p0/z, z0.b, 0		/* search for 0 */
	orrs	p4.b, p0/z, p2.b, p3.b		/* c | 0 */
	b.any	1b

	/* No C or 0 found.  Re-init FFR, increment, and loop.  */
	setffr
	incp	x0, p0.b
	b	0b

	.size	FUNC, . - FUNC
