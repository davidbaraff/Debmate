int linuxQT_image_width(void const* imagePtr);
int linuxQT_image_height(void const* imagePtr);

void linuxQT_delete_image(void const* ptr);
void linuxQT_image_draw(void const* imagePtr, void const* srcImagePtr,
                        double alpha, int xmin, int ymin, int width, int height);
void linuxQT_image_fill(void const* imagePtr, int r, int g, int b, int a,
                                   double alpha, int xmin, int ymin, int width, int height);
void linuxQT_image_stroke(void const* imagePtr,
                          double lineWidth,
                          int r, int g, int b, int a,
                          double alpha, int xmin, int ymin, int width, int height);
void linuxQT_image_circle(void const* imagePtr,
                          int r, int g, int b, int a,
                          double alpha, double x, double y, double radius);
void const* linuxQT_tinted_image(void const* imagePtr,
                                 int r, int g, int b, int a);
void const* linuxQT_resize_image(void const* imagePtr, int width, int height);
void const* linuxQT_image_copy(void const* imagePtr);
void const* linuxQT_empty_image(int width, int height);
void const* linuxQT_image_from_data(unsigned const char* data, int nbytes);
void const* linuxQT_image_to_pngData(void const* imagePtr);
void const* linuxQT_image_to_jpgData(void const* imagePtr);

int linuxQT_byte_array_size(void const* ptr);
char const* linuxQT_byte_array_data(void const* ptr);
void linuxQT_delete_byte_array(void const* ptr);




    
