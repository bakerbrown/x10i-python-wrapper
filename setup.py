from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
from Cython.Build import cythonize

extensions = [
    Extension("fflyusb_wrapper",             # name of the generated .cpp file
        sources=["fflyusb_wrapper.pyx"])    # name of the read .pyx file
]

setup(
    ext_modules=cythonize(extensions),
    cmdclass={'build_ext': build_ext}
)


