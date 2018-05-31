/*
 * strnlen - calculate the length of a string with limit.
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

	.globl	strnlen
	.type	strnlen, %function
	.p2align 4
strnlen:
	setffr				/* initialize FFR */
	mov	x2, 0			/* initialize len */
	b	1f

	.p2align 4
	/* We have off + vl <= max, and so may read the whole vector.  */
0:	ldff1b	z0.b, p0/z, [x0, x2]
	rdffrs	p1.b, p0/z
	b.nlast	2f

	/* First fault did not fail: the whole vector is valid.
	   Avoid depending on the contents of FFR beyond the branch.  */
	cmpeq	p2.b, p0/z, z0.b, 0
	b.any	8f
	incb	x2

1:	whilelo	p0.b, x2, x1
	b.last	0b

	/* We have off + vl < max.  Test for off == max before proceeding.  */
	b.none	9f

	ldff1b	z0.b, p0/z, [x0, x2]
	rdffrs	p1.b, p0/z
	b.nlast	2f

	/* First fault did not fail: the vector up to max is valid.
	   Avoid depending on the contents of FFR beyond the branch.
	   Compare for end-of-string, but there are no more bytes.  */
	cmpeq	p2.b, p0/z, z0.b, 0

	/* Found end-of-string or zero.  */
8:	brkb	p2.b, p0/z, p2.b
	mov	x0, x2
	incp	x0, p2.b
	ret

	/* First fault failed: only some of the vector is valid.
	   Perform the comparison only on the valid bytes.  */
2:	cmpeq	p2.b, p1/z, z0.b, 0
	b.any	8b

	/* No inequality or zero found.  Re-init FFR, incr and loop.  */
	setffr
	incp	x2, p1.b
	b	1b

	/* End of count.  Return max.  */
9:	mov	x0, x2
	ret

	.size	strnlen, . - strnlen
