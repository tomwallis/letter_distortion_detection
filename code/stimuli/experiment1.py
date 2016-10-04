'''	++++++++++++++++++     READ ME     ++++++++++++++++++
Creates an image with 4 (unflanked or flanked) in the 
periphery located letters. One of the letters is distorted. 

Parameters: 
distortiontype (bex/rf)
flankedtype (true/false) 
freqs (number of frequencies)
amps (number of amplitudes)
rep (number of each freq/amp stimuli) 

e.g. 'python experiment1.py bex false 2 2 1'
you will be asked to type in the frequencies and amplitudes later. 

If you want to use the default amplitudes/frequencies of the 
respective distortion type please type in a 0 for the number of 
amplitudes/frequencies
e.g. 'python experiment1.py bex false 0 0 1'

default values (rf): 
frequency = [2,3,4,5,8,12]
amplitude = [0.01, 0.0617, 0.1133, 0.1650, 0.2167, 0.2683, 0.32] 

default values (bex):
frequency = [2, 4, 6, 8, 16, 32]
amplitude = [0.5, 1, 1.5, 2, 2.5, 3, 5]
'''

## Generate distorted flanked and unflanked stimuli 
## Do imports
from __future__ import division
import numpy as np
import scipy
import sys
import os
from skimage import io, color, exposure, transform
from skimage import img_as_float
from skimage import img_as_uint
import psyutils as pu
from psyutils.image import show_im
import matplotlib.pyplot
from math import atan2, degrees, radians, atan, pi

io.use_plugin("matplotlib")

## set directories
this_dir = os.getcwd()
#im_dir = os.path.join(this_dir, 'source_ims')
out_dir = os.path.join(this_dir, 'stimuli_out')

## letter dictionary of Sloan letters
letter_dict = pu.im_data.sloan_letters()

''' --------  Helper functions  ---------'''

def bex_distorted_im(im, scale, f_peak):
    """A spatial distortion method based on a method by Peter Bex (see ref, below).

    Args:
        im (float): the image to distort.
        scale (int): determines the amplitude of distortion in pixels.
		f_peak (int): peak frequency of the filter.
    Returns:
        dist_image (float): the distorted image.

    Example:
        Distort an image:
            im = img_as_float(pu.im_data.tiger_grey())
            scale = 5
			f_peak = 4
            dist_im = bex_distorted_im(im, scale, f_peak) 
            pu.image.show_im(dist_im)

    Reference:
        Bex, P. J. (2010). (In) sensitivity to spatial distortion in natural
        scenes. Journal of Vision, 10(2), 23:1-15.

    """
    # log-exponential filter to create random-bandpass filtered noise samples as positional offset
    filt = pu.image.make_filter(im_x=im.shape[0], filt_type="log_exp", f_peak = f_peak, bw=0.5)
    
    # cosine window that reduces to zero over the padding region 
    cos_win = pu.image.cos_win_2d(im_x=im.shape[0], ramp=14)

	# horizontal and vertical positional offset 
    filt_noise_x = pu.image.make_filtered_noise(filt) * cos_win * scale
    filt_noise_y = pu.image.make_filtered_noise(filt) * cos_win * scale
    
	# disort image 
    dist_im = pu.image.grid_distort(im, x_offset=filt_noise_x, y_offset=filt_noise_y, 
                                   method="linear", fill_method=1)
    return(dist_im)

def rf_distorted_im(im, amplitude=0.1, frequency=3):
    """Creates a radial frequency modulated grid by modulating the distance from the center to every point 
    sinusoidally with a certain amplitude and frequency
    
    Based on a method by Dickinson et al. (see ref, below). 

    Args:
        im (float): the image to distort.
        amplitude (float): modulation amplitude, expressed as a proportion of the distance from the center of the 
                   unmodulated radius
        frequency (int): the frequency of modulation in 2*pi radians
        
    Returns:
        dist_image (float): the distorted image.

    Example:
        Distort an image:
            im = img_as_float(pu.im_data.tiger_grey())
            amplitude = 0.2
            frequency = 5
            dist_im = rf_distorted_im(im, amplitude, frequency) 
            pu.image.show_im(dist_im)

    Reference:
        Dickinson, J. E., Almeida, R. A., Bell, J. & Badcock, D. R. (2010). Global shape aftereffects have a local substrate: 
        A tilt aftereffect field. Journal of Vision,10 (13), 2.
    """
	
	# get radial distance 
    x = np.linspace(-20, 20, num=im.shape[0])
    xx, yy = np.meshgrid(x, x)    
    rad_dist = (xx**2 + yy**2)**0.5
    
    # randomise phase 
    rand_num = np.random.rand()*2*math.pi
	
	# angular distance
    ang_dist = ((rand_num+np.arctan2(xx, -yy))%(2*math.pi))-math.pi
 
    # modulate distance of each point from the center sinusoidally (cf. Dickinson et al. p. 3)
    rf_grid = rad_dist*(1+amplitude*(np.sin(frequency*ang_dist)))
    
    # calculate radial distance offset for each point
    delta_rad = rf_grid - rad_dist
   
    # cosine window that reduces to zero over the padding region 
    cos_win = pu.image.cos_win_2d(im_x=im.shape[0], ramp=14)
    
    # convert from polar to cartesian coordinates 
    x_offset = delta_rad * np.cos(ang_dist) * cos_win
    y_offset = delta_rad * np.sin(ang_dist) * cos_win

	# distort image
    dist_im = pu.image.grid_distort(im, x_offset=x_offset, y_offset=y_offset, 
                                   method="linear", fill_method=1)
    return(dist_im)

def set_letters(idx, letters, positions, pos, big_array, targ, scale, dist_type, dist_param):
    """Set a letter in a image at a given position. Distort letter before placing it, depending on the distortion type.
    
    Args:
        idx (int): the index of the letter to be set (in 'letters') 
        letters (string): array of letters
        positions (int): positions of all 4 letters 
        pos (int): random position indices 
        big_array (float): set the letter in this image
        targ (int): index of the target letter (letter to be distorted) 
        scale (int): amplitude, determines the distortion magnitude
        dist_type (string): distortion type 'undistorted', 'bex', 'rf'
        
    Returns:
        big_array (float): the image with the letter.

    Example:
        #Set 4 letters in a 1024x1024 pixel image, each with eccentricity of 320 pixel:
        letters=("D","H","K","N")
        positions = ((512, 192), (192, 512), (512, 832), (832, 512))
        # random positions for letters:  
        pos_rand = random_arr(0, len(letters), 1)     
        big_array = np.ones((1024,1024))
        # random target:
        targ = np.random.randint(0, len(letters))
        scale=5
        dist_type = 'bex'        
        for i in range(0, 4):
            big_array = set_letters(i, letters, positions, pos_rand[0], big_array, targ, scale, dist_type)
        show_im(big_array)
            
    """   
    im = letter_dict[letters[idx]]
     
    # resize letter to have a padding area of 14 pixels at each side
    im = transform.resize(im, (64, 64))
    pad = np.ones((92,92))
    im = pu.image.put_rect_in_rect(im, pad)
    
	# distort target letter
    if idx == targ:
        if dist_type == 'bex':
            im = bex_distorted_im(im, scale=scale, f_peak=dist_param)
        elif dist_type == 'rf':
            im = rf_distorted_im(im=im, amplitude=scale, frequency=dist_param)
    
    # place the letter into the array:
    this_x = positions[pos[idx]][0]
    this_y = positions[pos[idx]][1]
    big_array = pu.image.put_rect_in_rect(im, big_array, mid_x=this_x, mid_y=this_y) 
	
    return(big_array)   

def set_fixation_cross(big_array, x,y):      
    """Set a fixation cross in an image at position x,y. 
    
    Args:
        big_array (float): set the fixation cross into this image
        x (int): x position in pixels
        y (int): y position in pixels
    Returns:
        big_array (float): the image including the fixation cross.
    
    Example:
        big_array = np.ones((1024,1024))
        fixation_position = ((512,512))
        big_array = set_fixation_cross(big_array, fixation_position[0],fixation_position[1])
        show_im(big_array)
        
    """
	# fixation cross
    im = pu.misc.fixation_cross()
    # pad fixation cross
    pad = np.ones((272,272))
    im = pu.image.put_rect_in_rect(im, pad)
    # resize fixation cross:
    im = transform.resize(im, (24, 24))
    # set fixation cross in the image
    big_array = pu.image.put_rect_in_rect(im, big_array, mid_x=x, mid_y=y)    
    return(big_array)

def random_arr(start, stop, number):
    """Get 'number' random int arrays, each including the numbers from start to stop in a randomized order.
    
    Args:
        start (int): minimum value
        stop (int): maximum value
        number (int): number of arrays needed
    Returns:
        rand_arr (int): array with 'number' randomized int arrays, each with values from start to stop
    
    Example:
        start = 0
        stop = 4
        number = 2
        print(random_arr(start,stop,number))    
    """

    rand_arr = np.ones((number, stop-start), dtype=np.int)
    for i in range(0, number):
        rand = np.arange(start, stop)
        np.random.shuffle(rand)
        rand_arr[i] = rand
    return(rand_arr)


def flanker_pos(x,y,spacing):
    """Get flanker positions of a letter at position (x,y) with 'spacing' distance between the letter and flankers.
    Args:
        x (int): x value in pixels of the position of the letter around which the flankers should be placed.
        y (int): y value in pixels of the position of the letter around which the flankers should be placed.
        spacing (int): distance in pixels between letter and flanker
    Returns:
        pos (int): four flanker positions (left, bottom, right, top)
    
    Example:
        letter_pos = (512,512)
        spacing = 128
        print(flanker_pos(letter_pos[0],letter_pos[1],spacing))
    """
    #left, bottom, right, top flanker
    pos = ((x-spacing, y), (x, y+spacing), (x+spacing,y), (x, y-spacing))
    return (pos) 


def get_targetpos(targetpos, positions):
	"""Get target position as string (t,l,b,r) 
	Args:
        targetpos: position of the target in pixels
		positions: possible positions (top, left, bottom, right)
    Returns:
        position of the target as string (t,b,l,r)
   
    """
	if targetpos in positions:
		idx = positions.index(targetpos)
		if idx == 0: 
			return "t"
		elif idx == 1: 
			return "l"
		elif idx == 2: 
			return "b"
		elif idx == 3:
			return "r"
		else: 
			return("wrong get_targetpos idx")
	else: 
		return("targetpos is not in positions, see get_targetpos")


''' --------  Unflanked letter array  ---------'''
def unflanked_array(scale=50, dist_type='undistorted', letters=("D","H","K","N"), pos_rand=[[0,1,2,3]], targ=0, positions = ((512, 256), (256, 512), (512, 768), (768, 512)), dist_param = 0):
    """Create an unflanked letter image. 
    Args:
        scale (int): determines the magnitude of distortion (amplitude)
        dist_type (string): distortion type, 'undistorted', 'bex', 'rt' 
        letters (string): array of letters
        pos_rand (int): random position idices 
        targ (int): index of the target letter (letter to be distorted) 
        positions (int): positions of the letters in the unflanked letter image      
    Returns:
        big_array (float): the unflanked letter image. 
    
    Example 1:
        show_im(unflanked_array())
    Example 2:
        big_array = np.ones((1024,1024))
        dist_type = 'bex'
        
        # random positions for letters:  
        pos_rand = random_arr(0, len(letters), 1)        
        
        # random target:
        targ = np.random.randint(0, len(letters))
        
        big_array = unflanked_array(dist_type = dist_type, pos_rand = pos_rand, targ = targ)
        show_im(big_array)
        
    """
    big_array = np.ones((1024,1024))
    
    for i in range(0, len(letters)):
        big_array = set_letters(i, letters, positions, pos_rand[0], big_array, targ, scale, dist_type, dist_param)
    return(big_array)

	
''' --------  Flanked letter arrays  ---------'''

def flanked_array(scale=5, dist_type='undistorted', spacing=80, letters=("D","H","K","N"), flankers=("C", "O", "R", "Z"), pos_rand=[[0,1,2,3],[0,1,2,3],[0,1,2,3],[0,1,2,3],[0,1,2,3] ], targ=0, positions = ((512, 256), (256, 512), (512, 768), (768, 512)), dist_param = 0):
    """Create a flanked letter image. 
    Args:
        scale (int): determines the magnitude of distortion (amplitude)
        dist_type (string): distortion type, 'undistorted', 'bex', 'rt' 
        spacing (int): distance between letters and flankes in pixel 
        letters (string): array of letters
        flankers (string) : array of flanker letters
        pos_rand (int): random position indices 
        targ (int): index of the target letter (letter to be distorted) 
        positions (int): positions of the letters in the flanked letter image      
    Returns:
        big_array (float): the flanked letter image. 
    
    Example 1:
        show_im(flanked_array())
    Example 2:
        big_array = np.ones((1024,1024))
        dist_type = 'bex'
        
        # random positions for letters and flankers:  
        pos_rand = random_arr(0, len(letters), 5)        
        
        # random target:
        targ = np.random.randint(0, len(letters))
        
        big_array = flanked_array(dist_type = dist_type, pos_rand = pos_rand, targ = targ)
        show_im(big_array)
        
    """
    big_array = np.ones((1024,1024))
    # top, left, bottom, right 
    #positions = ((512, 256), (256, 512), (512, 768), (768, 512))
    
    # 4 flankers (left, bottom, right, top) per letter (top, left, bottom, right) 
    flanker_positions_top = flanker_pos(positions[0][0], positions[0][1], spacing)
    flanker_positions_left = flanker_pos(positions[1][0], positions[1][1], spacing)
    flanker_positions_bottom = flanker_pos(positions[2][0], positions[2][1], spacing)
    flanker_positions_right = flanker_pos(positions[3][0], positions[3][1], spacing)
    
    # flankers will not be distorted
    non_targ = 4

    for i in range(0, len(letters)):
        big_array = set_letters(i, letters, positions, pos_rand[0], big_array, targ, scale, dist_type, dist_param)
        big_array = set_letters(i, flankers, flanker_positions_top, pos_rand[1], big_array, non_targ, scale, dist_type, dist_param)
        big_array = set_letters(i, flankers, flanker_positions_left, pos_rand[2], big_array, non_targ, scale, dist_type, dist_param)
        big_array = set_letters(i, flankers, flanker_positions_bottom, pos_rand[3], big_array, non_targ, scale, dist_type, dist_param)
        big_array = set_letters(i, flankers, flanker_positions_right, pos_rand[4], big_array, non_targ, scale, dist_type, dist_param)
    return(big_array)

''' --------  Main stimulus generation function  ---------'''

def stim_gen(scales, reps, flanked, dist_type, dist_param):
	""" Creates stimuli. 
    Args:
        scales (int): determines the magnitude of distortion (amplitudes)
		reps : number of repitions per amplitude/frequency pair
		flanked: false (unflanked) or true (flanked) 
        dist_type (string): distortion type, bex', 'rf' 
		dist_param: frequency
    Example:
		reps = 10
		flankedtype = false
		frequency = [2, 4, 6, 8, 16, 32]
		amplitudes = [[0.5, 1, 1.5, 2, 2.5, 3, 5], [0.5, 1, 1.5, 2, 2.5, 3, 5]]
		for freq in range (0, len(frequency)):
			stim_gen(amplitudes, reps=reps, flanked = flankedtype, dist_type = 'bex', dist_param=frequency[freq])  
		
	"""
	pixel_per_deg = 40
	#spacing between letters and flankers in pixels
	spacing = 320*0.25
	letters=("D","H","K","N")
	flankers=("C", "O", "R", "Z")
	big_array = np.ones((1024,1024))
	fixation_position = ((512,512))
	
	#!!!DO NOT CHANGE THE ORDER: top, left, bottom, right !!!
	# positions = ((512, 256), (256, 512), (512, 768), (768, 512))
	# eccentricity = 8deg = 320pixel (40 pixel/deg)
	positions = ((512, 192), (192, 512), (512, 832), (832, 512))
	for scale in range(0, len(scales)):
		for rep in range (0, reps):    
			# random positions:
			pos_rand = random_arr(0, len(letters), 5)        
            
            # random target:
			targ = np.random.randint(0, len(letters))
            
            # get targetpos targ_pos "top", "left", "bottom", "right"
			targetpos = positions[pos_rand[0][targ]]
			targ_pos = get_targetpos(targetpos, positions)
            
            # save undistorted images
			if dist_type == 'bex':
				dist_type_out = 'bex_undistorted'
				dist_param_out = '_fpeak_'
			else:
				dist_type_out = 'rf_undistorted'
				dist_param_out = '_RF_'
				
			if not flanked:
                # create unflanked images
				big_array = unflanked_array(scale=scales[scale], dist_type='undistorted', letters=("D","H","K","N"), pos_rand=pos_rand, targ=targ, positions=positions, dist_param= dist_param)
				big_array = set_fixation_cross(big_array, fixation_position[0],fixation_position[1])
				scipy.misc.imsave(os.path.join(out_dir, "unflanked_" + dist_type_out + '_freq_' + str(dist_param) + "_amplitude_" + str(scales[scale]) + "_rep_" + str(rep) + "_" + targ_pos + "_" + letters[targ] + ".png"),
                                  exposure.rescale_intensity(big_array, out_range = (0, 1)))
				
				big_array = unflanked_array(scale=scales[scale], dist_type=dist_type, letters=("D","H","K","N"), pos_rand=pos_rand, targ=targ, positions=positions, dist_param= dist_param)
				big_array = set_fixation_cross(big_array, fixation_position[0],fixation_position[1])
				scipy.misc.imsave(os.path.join(out_dir, "unflanked_" + str(dist_type) + '_freq_' + str(dist_param) + "_amplitude_" + str(scales[scale]) + "_rep_" + str(rep) + "_" + targ_pos + "_" + letters[targ] + ".png"),
                                  exposure.rescale_intensity(big_array, out_range = (0, 1)))
			else: 
                #crate flanked images
				big_array = flanked_array(scale=scales[scale], dist_type='undistorted', spacing=spacing, pos_rand=pos_rand, targ=targ, positions=positions, dist_param = dist_param)
				big_array = set_fixation_cross(big_array, fixation_position[0],fixation_position[1])
				scipy.misc.imsave(os.path.join(out_dir, "flanked_" + dist_type_out + '_freq_' + str(dist_param) + "_amplitude_" + str(scales[scale]) + "_rep_" + str(rep) + "_" + targ_pos + "_" + letters[targ] + "_" + str(spacing/40) + ".png"), 
                         exposure.rescale_intensity(big_array, out_range = (0, 1)))
				
				big_array = flanked_array(scale=scales[scale], dist_type=dist_type, spacing=spacing, pos_rand=pos_rand, targ=targ, positions=positions, dist_param = dist_param)
				big_array = set_fixation_cross(big_array, fixation_position[0],fixation_position[1])
				scipy.misc.imsave(os.path.join(out_dir, "flanked_" + str(dist_type) + '_freq_' + str(dist_param) + "_amplitude_" + str(scales[scale]) + "_rep_" + str(rep) + "_" + targ_pos + "_" + letters[targ] + "_" + str(spacing/40) + ".png"), 
                             exposure.rescale_intensity(big_array, out_range = (0, 1)))

#Bex style generation
def generate_bex(frequency, amplitudes, flankedtype=False, reps=10):
    #distortion frequency (c/deg) 
    #frequency = [2, 4, 6, 8, 16, 32]
    #amplitudes = [[0.5, 1, 1.5, 2, 2.5, 3, 5], [0.5, 1, 1.5, 2, 2.5, 3, 5]]
    for freq in range (0, len(frequency)):
        stim_gen(amplitudes, reps=reps, flanked = flankedtype, dist_type = 'bex', dist_param=frequency[freq])  

#RF style generation
def generate_rf(frequency, amplitudes, flankedtype=False, reps=10):
    #frequency = [2,3,4,5,8,12]
    #amplitude = [[0.01, 0.0617, 0.1133, 0.1650, 0.2167, 0.2683, 0.32], [0.01, 0.0617, 0.1133, 0.1650, 0.2167, 0.2683, 0.32]] 
    for freq in range (0, len(frequency)):
        stim_gen(amplitudes, reps=reps, flanked = flankedtype, dist_type = 'rf', dist_param=frequency[freq])


''' --------  Main function  ---------'''
		
file_name, distortiontype, flankedtype, freqs, amps, rep = sys.argv
# check input arguments
if sys.argv <=6:
	print('not enough arguments')
else:
	distortiontype = sys.argv[1]
	if sys.argv[2] == 'true' or sys.argv[2] == 'True':
		flankedtype = True
	else: 
		flankedtype = False
	freqs = int(sys.argv[3])
	amps = int(sys.argv[4])
	rep = int(sys.argv[5])
	frequency = []
	amplitude = []
	
	# set default frequencies and amplitudes
	# rf distortion type
	if distortiontype == 'rf':
		if freqs == 0:
			frequency = [2,3,4,5,8,12]
		else:
			for f in range(0, freqs):
				x = input("Enter next frequency:")
				frequency.append(x)
		if amps == 0:
			amplitude = [0.01, 0.0617, 0.1133, 0.1650, 0.2167, 0.2683, 0.32] 
		else: 
			for a in range(0, amps):
				y = input("Enter next amplitude:")
				amplitude.append(y)
		generate_rf(frequency, amplitude, flankedtype=flankedtype, reps=rep)
	
	# bex distortion type
	elif distortiontype == 'bex':
		if freqs == 0:
			frequency = [2, 4, 6, 8, 16, 32]
		else:
			for f in range(0, freqs):
				x = input("Enter next frequency:")
				frequency.append(x)
		if amps == 0:
			amplitude = [0.5, 1, 1.5, 2, 2.5, 3, 5]
		else: 
			for a in range(0, amps):
				y = input("Enter next amplitude:")
				amplitude.append(y)
		generate_bex(frequency, amplitude, flankedtype=flankedtype, reps=rep)
	else: 
		print('distortiontype not known')

