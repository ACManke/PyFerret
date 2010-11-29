/*
 *		Copyright IBM Corporation 1989
 *
 *                      All Rights Reserved
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose and without fee is hereby granted,
 * provided that the above copyright notice appear in all copies and that
 * both that copyright notice and this permission notice appear in
 * supporting documentation, and that the name of IBM not be
 * used in advertising or publicity pertaining to distribution of the
 * software without specific, written prior permission.
 *
 * IBM DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
 * ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL
 * IBM BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR
 * ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
 * WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
 * ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
 * SOFTWARE.
 *
 *
 * University of Illinois at Urbana-Champaign
 * Department of Computer Science
 * 1304 W. Springfield Ave.
 * Urbana, IL	61801
 *
 * (C) Copyright 1987, 1988 by The University of Illinois Board of Trustees.
 * All rights reserved.
 *
 * Tool: X 11 Graphical Kernel System
 * Author: Gregory Scott Rogers
 * Author: Sung Hsien Ching Kelvin
 * Author: Yu Pan
 * 
 * make error message header file  from gks_errors.h file
 *
 * usage:mkerrmsg < gks_errors.h > gkserrmsg.h 
 */

/*LINTLIBRARY*/

#include <wchar.h>
#include "udposix.h"
#include <stdio.h>
#include <string.h>

#ifndef lint
    static char	*rcsid	="$Id$";
    static char	*afsid	="$__Header$";
#endif


main()
{
    char            line[1024], dstr[30], estr[30];
    char           *cp;
    int             cnt = 0, num, max = 201;
    int             first = 1;

    (void) printf("/*\n");
    (void) printf(
	" * Do not edit this file, it is generated automatically from\n");
    (void) printf(" * the gks_errors.h file via mkerrmsg.c.\n");
    (void) printf(" */\n");
    (void) printf(
	"\n#ifndef GKSERRMSG_H_INCLUDED\n#define GKSERRMSG_H_INCLUDED\n");

    (void) printf("#ifdef GKS_ERROR_C\n");
    while (gets(line) != NULL) {
	if (strncmp("#define", line, 7) != 0)
	    puts(line);
	else {
	    if (first) {
		(void) printf("static char *GKSErrorMessages0to200[] = {\n");
		first = 0;
		cnt = 0;
		max = 201;
	    }
	    (void) sscanf(line, "%s %s %d", dstr, estr, &num);
	    if (num > max) {
		if (max == 201) {
		    for (; cnt < max; cnt++)
			(void) printf("/* %d */	(char *)NULL,\n", cnt);
		    (void) printf("};\n");
		    (void) printf(
			"static char *GKSErrorMessages300to309[] = {\n");
		    cnt = 300;
		    max = 310;
		} else if (max == 310) {
		    for (; cnt < max; cnt++)
			(void) printf("/* %d */	(char *)NULL,\n", cnt);
		    (void) printf("};\n");
		    (void) printf(
			"static char *GKSErrorMessages2000to2000[] = {\n");
		    cnt = 2000;
		    max = 2004;
		} else
		    (void) printf("};\n");
	    }
	    for (; cnt < num; cnt++)
		(void) printf("/* %d */	(char *)NULL,\n", cnt);
	    cnt++;
	    (void) printf("/* %s %d */	", estr, num);
	    cp = strrchr(line, '*');
	    cp--;
	    *cp = '\0';
	    cp = strrchr(line, '*');
	    cp += 2;
	    (void) printf("\"%s\",\n", cp);
	}
    }
    (void) printf("};\n");
    (void) printf("\n#else /* GKS_ERROR_C not defined */\n\n");
    (void) printf("extern char *GKSErrorMessages0to200[];\n");
    (void) printf("extern char *GKSErrorMessages300to309[];\n");
    (void) printf("extern char *GKSErrorMessages2000to2000[];\n");
    (void) printf("\n#endif\n");
    (void) printf("\n#endif\t/* GKSERRMSG_H_INCLUDED not defined */\n");
    return 0;
}
