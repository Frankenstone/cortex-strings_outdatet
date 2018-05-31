/*
 * memcmp - compare memory
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

	.globl	memcmp
	.type	memcmp, %function
	.p2align 4
memcmp:
	mov	x3, 0			/* initialize off */

0:	whilelo	p0.b, x3, x2		/* while off < max */
	b.none	9f

	ld1b	z0.b, p0/z, [x0, x3]	/* read vectors bounded by max.  */
	ld1b	z1.b, p0/z, [x1, x3]

	/* Increment for a whole vector, even if we've only read a partial.
	   This is significantly cheaper than INCP, and since OFF is not
	   used after the loop it is ok to increment OFF past MAX.  */
	incb	x3

	cmpne	p1.b, p0/z, z0.b, z1.b	/* while no inequalities */
	b.none	0b

	/* Found inequality.  */
1:	brkb	p1.b, p0/z, p1.b	/* find first such */
	lasta	w0, p1, z0.b		/* extract each byte */
	lasta	w1, p1, z1.b
	sub	x0, x0, x1		/* return comparison */
	ret

	/* Found end-of-count.  */
9:	mov	x0, 0			/* return equality */
	ret

	.size	memcmp, . - memcmp
