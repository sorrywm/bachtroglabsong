# bachtroglabsong
Files related to analysis of courtship song in nasuta, ananassae, virilis, and athabasca subgroups

This repo contains a collection of wrapper scripts for processing multi-channel .wav audio files and corresponding spreadsheets formatted as in the example RecordingTemplate.xlsx, which contain information about flies whose songs have been recorded in the multi-channel .wav files. Scripts are written primarily in MATLAB, with some post-processing in R. Pulse song identification scripts rely on software developed by the Stern and Murthy labs at Princeton, specifically FlySongSegmenter (available at https://github.com/FlyCourtship/FlySongSegmenter) and FlySongClusterSegment (in development).

The latest/most broadly applicable script for each of the following tasks is listed below:<p>
1) Extract individual channels from a 32-channel .wav file:
makeWaves_savio_raw.m 
2) Implement a high-pass filter on an individual .wav file (using Ty Hedrick's wrapper for the Matlab Signal Processing Toolbox Butterworth filter):
FilterAndPlot.m 
3) Generate pulse templates from a single-channel .wav file:
CreateSpeciesTemplatesFiltLoadOpts.m 
4) Identify pulses within a single-channel .wav file:
RunClusteringOneChannelFilt5pmLoadOpts.m 
5) Characterize flies in spreadsheet by contents of Notes cell (currently identifies indicators of wing damage, though this could be modified for other text searches):
findDamagedMales.m 
6) Summarize parameters of pulse song from the output of pulse identification for a set of songs:
SummarizeSongStatdist.R

The MATLAB files nasutaoptionssavio.mat and virilisoptionssavio.mat contain both system-specific paths for files, scripts, and dependencies, and parameters optimized for these species' songs. The folderMap.mat file contains a mapping of species names to the four clades for which the Bachtrog lab has recordings.

COPYRIGHT
Copyright ©2016. The Regents of the University of California (Regents). All Rights Reserved. Permission to use, copy, modify, and distribute this software and its documentation for educational, research, and not-for-profit purposes, without fee and without a signed licensing agreement, is hereby granted, provided that the above copyright notice, this paragraph and the following two paragraphs appear in all copies, modifications, and distributions. Contact The Office of Technology Licensing, UC Berkeley, 2150 Shattuck Avenue, Suite 510, Berkeley, CA 94720-1620, (510) 643-7201, otl@berkeley.edu, http://ipira.berkeley.edu/industry-info for commercial licensing opportunities.

Created by Wynn Meyer, Matthew Nalley, and Hannah Soltz, Department of Integrative Biology, University of California, Berkeley.

IN NO EVENT SHALL REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF REGENTS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

REGENTS SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED HEREUNDER IS PROVIDED "AS IS". REGENTS HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
