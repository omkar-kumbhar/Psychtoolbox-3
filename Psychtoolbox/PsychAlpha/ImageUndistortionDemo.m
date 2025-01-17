function ImageUndistortionDemo(calibfilename, imagefilename)
% ImageUndistortionDemo(calibfilename [, imagefilename])
%
% A very sketchy demo on how to do gpu accelerated geometric
% undistortion of images.
%
% 'calibfilename' Name of a calibration file, as also used by
% PsychImaging's 'GeometryCorrection' tasks, and generated by one
% of the available calibration procedures, e.g., DisplayUndistortionBVL,
% DisplayUndistortionCSV, DisplayUndistortionBezier, ...
%
% 'imagefilename' Optional name of image file to process. If left out,
% our standardy bunny image will be used. If set to 'checkerboard', a
% checkerboard pattern will be used.
%
% Press any key to exit the demo after the undistorted image was
% displayed.
%
% This demo is more a template for you to get started writing suitable
% code for your purpose than a ready made plug & play solution.
%

% History:
% 7/27/2008 mk Written.
% 7/25/2015 mk Updated.

% Basic check if runnning on PTB-3:
AssertOpenGL;

if nargin < 1 || isempty(calibfilename)
  error('Required calibfilename missing.');
end

if nargin < 2
  imagefilename = [];
end

if isempty(imagefilename)
  imagefilename = [PsychtoolboxRoot 'PsychDemos/konijntjes1024x768.jpg'];
end

% Choose output screen as usual:
screenid=max(Screen('Screens'));

% Only enable support for fast offscreen windows, don't need full blown pipeline here:
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');
w=PsychImaging('OpenWindow', screenid, 0);

if ~strcmpi(imagefilename, 'checkerboard')
  % Use our standard bunny picture as some test case:
  img = imread(imagefilename);
else
  % Use a checkerboard pattern:
  [ww, wh] = Screen('WindowSize', w);
  checkSize = 105;
  img = 255 * double(checkerboard(checkSize,round(wh/checkSize/2),round(ww/checkSize/2)) > 0.5);
end

mytex=Screen('MakeTexture', w, img);

% Size of input image to apply correction to -- The size of the offscreen window:
srcSize = Screen('Rect', mytex);

% Setup oversized offscreen window: This as an example of an oversized
% input image buffer. Could also use a normal texture from
% Screen('MakeTexture') or any other function that returns texture handles:
[exampleImage, woffrect] = Screen('OpenOffscreenWindow', w, 0, srcSize);

% Create an offscreen window of the size of the wanted undistorted and
% scaled down image, as a target buffer:
undistortedImage = Screen('OpenOffscreenWindow', w, 128, srcSize);

% Create an empty image processing operator for onscreen window 'w':
gloperator = CreateGLOperator(w);

% Create and add image undistortion operation to gloperator:
% Setup calibration: 'calibfilename' is the path to the calibration file
% that defines undistortion and scaling: 73, 73 is resolution of warp-mesh,
% if the used calibration method is DisplayUndistortionBVL, otherwise the
% resolution parameters are ignored by the other calibration methods.
%
% Higher numbers for mesh resolution == finer undistortion but longer draw
% time. 'exampleImage' must be the handle to a texture or offscreen window
% that has the same size, color depth and format as the input images you're
% gonna use later on, otherwise weird things will happen.
AddImageUndistortionToGLOperator(gloperator, exampleImage, calibfilename, 0, 73, 73);

% Draw original image into exampleImage, scale it up to offscreen window size:
Screen('DrawTexture', exampleImage, mytex, [], woffrect);

% Draw some centered text for illustration...
Screen('TextSize', exampleImage, 64);
DrawFormattedText(exampleImage, 'Hello World', 'center', 'center', [0 255 0]);

% Ok, exampleImage contains the "distorted" oversized image we want to
% undistort and scale by application of our gloperator. Apply it,
% undistortedImage will contain the new undistorted image:
undistortedImage = Screen('TransformTexture', exampleImage, gloperator, [], undistortedImage);

% Draw undistorted image to onscreen window:
Screen('DrawTexture', w, undistortedImage);

% Show it:
Screen('Flip', w);

% Wait for keypress:
KbStrokeWait;

% Close all windows and ressources:
Screen('CloseAll');

return;
