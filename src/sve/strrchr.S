/*
 * strrchr - find the last of a character in a string
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

	.globl	strrchr
	.type	strrchr, %function
	.p2align 4
strrchr:
	dup	z1.b, w1		/* replicate byte across vector */
	setffr				/* initialize FFR */
	ptrue	p1.b			/* all ones; loop invariant */
	mov	x2, 0			/* no match found so far */
	pfalse	p2.b

	.p2align 4
	/* Read a vector's worth of bytes, stopping on first fault.  */
0:	ldff1b	z0.b, p1/z, [x0, xzr]
	rdffrs	p0.b, p1/z
	b.nlast	1f

	/* First fault did not fail: the whole vector is valid.
	   Avoid depending on the contents of FFR beyond the branch.  */
	incb	x0, all			/* skip bytes this round */
	cmpeq	p3.b, p1/z, z0.b, 0	/* search for 0 */
	b.any	3f

	cmpeq	p3.b, p1/z, z0.b, z1.b	/* search for c; no eos */
	b.none	0b

	mov	x2, x0			/* save advanced base */
	mov	p2.b, p3.b		/* save current search */
	b	0b

	/* First fault failed: only some of the vector is valid.
	   Perform the comparisions only on the valid bytes.  */
1:	cmpeq	p3.b, p0/z, z0.b, 0	/* search for 0 */
	b.any	2f

	cmpeq	p3.b, p0/z, z0.b, z1.b	/* search for c; no eos */
	mov	x3, x0
	incp	x0, p0.b		/* skip bytes this round */
	setffr				/* re-init FFR */
	b.none	0b

	addvl	x2, x3, 1		/* save advanced base */
	mov	p2.b, p3.b		/* save current search */
	b	0b

	/* Found end-of-string.  */
2:	incb	x0, all			/* advance base */
3:	brka	p3.b, p1/z, p3.b	/* mask after first 0 */
	cmpeq	p3.b, p3/z, z0.b, z1.b	/* search for c not after eos */
	b.any	4f

	/* No C within last vector.  Did we have one before?  */
	cbnz	x2, 5f
	mov	x0, x2			/* restore advanced base */
	mov	p3.b, p2.b		/* restore saved search */

	/* Find the *last* match in the predicate.  This is slightly
	   more complicated than finding the first match.  */
4:	rev	p3.b, p3.b		/* reverse the bits */
	brka	p3.b, p3/z, p3.b	/* find position of last match */
	decp	x0, p3.b		/* retard pointer to last match */
	ret

	/* No C whatsoever.  Return NULL.  */
5:	mov	x0, 0
	ret

	.size	strrchr, . - strrchr
