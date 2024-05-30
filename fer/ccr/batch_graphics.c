/*
*
*  
* 5/2024 Changes to let -png mode pass in a name, hack was to 
*        use the my_metaname argument for both -batch and
*        for -png, marking up the name sent in for -batch.
*	     batch_mode is a flag for batch mode in which case
*		 issue the warning.
*/

#include <Python.h> /* make sure Python.h is first */
#include <assert.h>
#include <string.h>
#include "ferret.h"
#include "grdel.h"

/* set_batch_graphics */
void set_batch_graphics(char *outfile, int *pngonly)
{
  int length;
  int batch_mode;

  assert( outfile != NULL );
  length = strlen(outfile);
  /*
   * This can be called either with (-batch) or without
   * (-gif or -unmapped) a filename.  Only call
   * save_metafile_name if a filename is given (-batch or -png).
   */
  if ( length > 0 ) {
     FORTRAN(save_metafile_name)(outfile, &length, &batch_mode);
     if ( batch_mode > 0 )
     {FORTRAN(assign_modemeta)();
     }
  }

  /* 
   * GKS metafile format no longer supported. The "-batch"
   * and "-unmapped" options do not change the workflow.
   * If one of these option is given, however, windows are not
   * made visible.  This allows the use of a faster graphics engine.
   * -gif or -png sets the Cairo surface to an image surface
   *  allowing even faster processing, but with limitations.
   */
  FORTRAN(fgd_set_unmapped_default)(pngonly);
}

