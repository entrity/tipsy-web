var ResizeableImage;

(function () {
  
  var event_state = {};

  ResizeableImage = function (image_target, options) {
    options || (options = {});
    
    // Some variable and settings
    this.orig_src = new Image()
    this.image_target = $(image_target)[0];
    this.constrain   = ('constrain' in options) ? options.constrain : true;
    this.min_width   = options.minWidth || 60;
    this.min_height  = options.minHeight || 60;
    this.max_width   = options.maxWidth || 900;
    this.max_height  = options.maxHeight || 900;
    this.resize_canvas = document.createElement('canvas');
    
    // When resizing, we will always use this copy of the original as the base
    this.orig_src.src = this.image_target.src;

    // Wrap the image with the container and add resize handles
    $(image_target).wrap('<div class="resize-container"></div>')
    .before('<span class="resize-handle resize-handle-nw"></span>')
    .before('<span class="resize-handle resize-handle-ne"></span>')
    .after('<span class="resize-handle resize-handle-se"></span>')
    .after('<span class="resize-handle resize-handle-sw"></span>');

    // Assign the container to a variable
    this.$container = $(image_target).parent('.resize-container');

    // Add events
    var self = this;
    this.$container.on('mousedown touchstart', '.resize-handle', function(){
      event_state.imageEditor = self;
    });
    this.$container.on('mousedown touchstart', 'img', function(){
      event_state.imageEditor = self;
    });
    this.$container.on('mousedown touchstart', '.resize-handle', startResize);
    this.$container.on('mousedown touchstart', 'img', startMoving);
  };

  Object.defineProperties(ResizeableImage.prototype, {

    resizeImage: {
      value: function(width, height){
        this.resize_canvas.width = width;
        this.resize_canvas.height = height;
        this.resize_canvas.getContext('2d').drawImage(this.orig_src, 0, 0, width, height);   
        $(this.image_target).attr('src', this.resize_canvas.toDataURL("image/png"));  
      }
    },

    crop: {
      value: function(){
        //Find the part of the image that is inside the crop box
        var crop_canvas,
            overlay = $('.overlay'),
            left = overlay.offset().left - this.$container.offset().left,
            top =  overlay.offset().top - this.$container.offset().top,
            width = overlay.width(),
            height = overlay.height();
    		
        crop_canvas = document.createElement('canvas');
        crop_canvas.width = width;
        crop_canvas.height = height;
        
        crop_canvas.getContext('2d').drawImage(this.image_target, left, top, width, height, 0, 0, width, height);
        return crop_canvas.toDataURL("image/png");
      }
    },

  });

  startResize = function(e){
    e.preventDefault();
    e.stopPropagation();
    saveEventState(e);
    $(document).on('mousemove touchmove', resizing);
    $(document).on('mouseup touchend', endResize);
  };

  endResize = function(e){
    e.preventDefault();
    $(document).off('mouseup touchend', endResize);
    $(document).off('mousemove touchmove', resizing);
  };

  saveEventState = function(e){
    var $container = event_state.imageEditor.$container;

    // Save the initial event details and container state
    event_state.container_width = $container.width();
    event_state.container_height = $container.height();
    event_state.container_left = $container.offset().left; 
    event_state.container_top = $container.offset().top;
    event_state.mouse_x = (e.clientX || e.pageX || e.originalEvent.touches[0].clientX) + $(window).scrollLeft(); 
    event_state.mouse_y = (e.clientY || e.pageY || e.originalEvent.touches[0].clientY) + $(window).scrollTop();
  
    // This is a fix for mobile safari
    // For some reason it does not allow a direct copy of the touches property
    if(typeof e.originalEvent.touches !== 'undefined'){
      event_state.touches = [];
      $.each(e.originalEvent.touches, function(i, ob){
        event_state.touches[i] = {};
        event_state.touches[i].clientX = 0+ob.clientX;
        event_state.touches[i].clientY = 0+ob.clientY;
      });
    }
    event_state.evnt = e;
  };

  resizing = function(e){
    var constrain = event_state.imageEditor.constrain;
    var orig_src = event_state.imageEditor.orig_src;
    var $container = event_state.imageEditor.$container;
    var min_width = event_state.imageEditor.min_width;
    var min_height = event_state.imageEditor.min_height;
    var max_width = event_state.imageEditor.max_width;
    var max_height = event_state.imageEditor.max_height;
    var mouse={},width,height,left,top,offset=$container.offset();
    mouse.x = (e.clientX || e.pageX || e.originalEvent.touches[0].clientX) + $(window).scrollLeft(); 
    mouse.y = (e.clientY || e.pageY || e.originalEvent.touches[0].clientY) + $(window).scrollTop();
    
    // Position image differently depending on the corner dragged and constraints
    if( $(event_state.evnt.target).hasClass('resize-handle-se') ){
      width = mouse.x - event_state.container_left;
      height = mouse.y  - event_state.container_top;
      left = event_state.container_left;
      top = event_state.container_top;
    } else if($(event_state.evnt.target).hasClass('resize-handle-sw') ){
      width = event_state.container_width - (mouse.x - event_state.container_left);
      height = mouse.y  - event_state.container_top;
      left = mouse.x;
      top = event_state.container_top;
    } else if($(event_state.evnt.target).hasClass('resize-handle-nw') ){
      width = event_state.container_width - (mouse.x - event_state.container_left);
      height = event_state.container_height - (mouse.y - event_state.container_top);
      left = mouse.x;
      top = mouse.y;
      if(constrain || e.shiftKey){
        top = mouse.y - ((width / orig_src.width * orig_src.height) - height);
      }
    } else if($(event_state.evnt.target).hasClass('resize-handle-ne') ){
      width = mouse.x - event_state.container_left;
      height = event_state.container_height - (mouse.y - event_state.container_top);
      left = event_state.container_left;
      top = mouse.y;
      if(constrain || e.shiftKey){
        top = mouse.y - ((width / orig_src.width * orig_src.height) - height);
      }
    }
  
    // Optionally maintain aspect ratio
    if(constrain || e.shiftKey){
      height = width / orig_src.width * orig_src.height;
    }

    if(width > min_width && height > min_height && width < max_width && height < max_height){
      // To improve performance you might limit how often resizeImage() is called
      event_state.imageEditor.resizeImage(width, height);
      // Without this Firefox will not re-calculate the the image dimensions until drag end
      $container.offset({'left': left, 'top': top});
    }
  }

  startMoving = function(e){
    e.preventDefault();
    e.stopPropagation();
    saveEventState(e);
    $(document).on('mousemove touchmove', moving);
    $(document).on('mouseup touchend', endMoving);
  };

  endMoving = function(e){
    e.preventDefault();
    $(document).off('mouseup touchend', endMoving);
    $(document).off('mousemove touchmove', moving);
  };

  moving = function(e){
    var  mouse={}, touches;
    e.preventDefault();
    e.stopPropagation();
    
    touches = e.originalEvent.touches;
    
    mouse.x = (e.clientX || e.pageX || touches[0].clientX) + $(window).scrollLeft(); 
    mouse.y = (e.clientY || e.pageY || touches[0].clientY) + $(window).scrollTop();
    event_state.imageEditor.$container.offset({
      'left': mouse.x - ( event_state.mouse_x - event_state.container_left ),
      'top': mouse.y - ( event_state.mouse_y - event_state.container_top ) 
    });
    // Watch for pinch zoom gesture while moving
    if(event_state.touches && event_state.touches.length > 1 && touches.length > 1){
      var width = event_state.container_width, height = event_state.container_height;
      var a = event_state.touches[0].clientX - event_state.touches[1].clientX;
      a = a * a; 
      var b = event_state.touches[0].clientY - event_state.touches[1].clientY;
      b = b * b; 
      var dist1 = Math.sqrt( a + b );
      
      a = e.originalEvent.touches[0].clientX - touches[1].clientX;
      a = a * a; 
      b = e.originalEvent.touches[0].clientY - touches[1].clientY;
      b = b * b; 
      var dist2 = Math.sqrt( a + b );

      var ratio = dist2 /dist1;

      width = width * ratio;
      height = height * ratio;
      // To improve performance you might limit how often resizeImage() is called
      event_state.imageEditor.resizeImage(width, height);
    }
  };

})();
