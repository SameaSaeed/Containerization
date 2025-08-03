# Use the official Jupyter base notebook as parent image
FROM jupyter/base-notebook:latest

# Set the working directory
WORKDIR /home/jovyan

# Switch to root user to install packages
USER root

# Install system dependencies if needed
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Switch back to jovyan user
USER jovyan

# Install Python packages
RUN pip install --no-cache-dir \
    tensorflow==2.13.0 \
    scikit-learn \
    pandas \
    numpy \
    matplotlib \
    seaborn \
    plotly \
    jupyter-widgets \
    joblib

# Enable jupyter widgets
RUN jupyter nbextension enable --py widgetsnbextension

# Set the default command
CMD ["start-notebook.sh"]