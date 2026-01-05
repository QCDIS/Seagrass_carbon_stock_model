# How to run Seagrass Carbon Stock Model

This is the instruction on how to run the seagrass carbon stock model in NaaVRE.

We provide two options to run the workflow:

* Option 1: Run the workflow for a single site using **parameter** input.
* Option 2: Run the workflow for multiple sites using **excel file** input.

## <a name='RunningtheworkflowinNaaVRE'></a>Running the workflow in NaaVRE

To run the workflow, you need to open the virtual lab in NaaVRE. If you are not in NaaVRE, click the link to the virtual lab (https://beta.naavre.net/vreapp/vl/blue-carbon) and press the `Launch my instance` button.

### <a name='Option1:RuntheworkflowfromparameterinputGUI'></a>Option 1: Run the workflow for a single site using **parameter** input

To execute the workflow do the following:

<div style="display: inline-block">

|      | Step | Action |
| ---- | ---- | ------ |
| 1    | Open the workflow file | open [run model from parameter input](./workflows/run_model_from_Param_input.naavrewf) |
| 2    | Start workflow         | ![img_tutorial_01-Run_workflow.png](documentation/images/img_tutorial_01-Run_workflow.png "Start workflow") |
| 3    | Set parameter values   | ![img_tutorial_02a-Set_default_parameters.png](documentation/images/img_tutorial_02a-Set_default_parameters.png "Set parameter values") | 
| 3.1  | Fill in default values | ![img_tutorial_02-Use_default_parameters.png](documentation/images/img_tutorial_02-Use_default_parameters.png "Default parameter values")
| 3.2  | Change values          | latitude, decimal degrees</br>longitude, decimal degrees</br>seagrass_species (One of the European seagrass names)</br><ul style="color:red;"><li>Cymodocea nodosa</li><li>Halophila stipulacea</li><li>Posidonia oceanica</li><li>Zostera marina</li><li>Zostera noltei</li><li>Zostera marina and Cymodocea nodosa</li><li>Zostera marina and Zostera noltei</li><li>Unspecified</li></ul> |
| 4    | Execute workflow       | ![img_tutorial_03-Exec_workflow.png](documentation/images/img_tutorial_03-Exec_workflow.png "Execute workflow") |
| 5    | Check the progress     | ![img_tutorial_04-Progress.png](documentation/images/img_tutorial_04-Progress.png "Check the progress") |

> Option: the details of the progress can be found by pressing `Show in workflow engine` or https://staging.demo.naavre.net/argowf/workflows, login required.

</div>

### <a name='Option2:RuntheworkflowfromexcelfileinputGUI'></a>Option 2: Run the workflow for multiple sites using **excel file** input

To execute the workflow do the following:

<div style="display: inline-block">

|      | Step | Action |
| ---- | ---- | ------ |
| 1    | Open the workflow file | open [run model from Excel upload](./workflows/run_model_from_Excel_upload.naavrewf) |
| 1.a  | <ol><li>Download the `Template-Seagrass_site_data.xlsx` by right click</li><li>Edit the `Template-Seagrass_site_data.xlsx`</li><li>Save as `Seagrass_site_data.xlsx`</li></ol></br><small><ul><li>Instructions sheet: Explain the input data</li><li>Data sheet: The input data used for prediction</li></ul></small> | ![img_tutorial_05-Template_file.png](documentation/images/img_tutorial_05-Template_file.png "Template file") |
| 1.b  | Upload the `Seagrass_site_data.xlsx` to the `data` folder       | 1. Double click `data` folder ![img_tutorial_06a-Upload_file.png](documentation/images/img_tutorial_06a-Upload_file.png "Upload") </br> 2. Click `upload` icon ![img_tutorial_06b-Upload_file.png](documentation/images/img_tutorial_06b-Upload_file.png "data folder") </br> 3. Successfuly uploaded ![img_tutorial_06c-Upload_file.png](documentation/images/img_tutorial_06c-Upload_file.png "data folder") |
| 1.c  | Click `Git public` back to workspace   | ![img_tutorial_06d-Back_to_root.png](documentation/images/img_tutorial_06d-Back_to_root.png "Back") |
| 2    | Start workflow         | ![img_tutorial_01-Run_workflow.png](documentation/images/img_tutorial_01-Run_workflow.png "Start workflow") |
| 3    | Set parameter values   | ![img_tutorial_02b-Set_default_parameters.png](documentation/images/img_tutorial_02b-Set_default_parameters.png "Set parameter values") |
| 3.1  | Fill values by default | ![img_tutorial_02-Use_default_parameters.png](documentation/images/img_tutorial_02-Use_default_parameters.png "Default parameter values")
| 3.2  | Change file name       | Fill the uploaded excel file name `Seagrass_site_data.xlsx` |
| 4    | Execute workflow       | ![img_tutorial_03-Exec_workflow.png](documentation/images/img_tutorial_03-Exec_workflow.png "Execute workflow") |
| 5    | Check the progress     | ![img_tutorial_04-Progress.png](documentation/images/img_tutorial_04-Progress.png "Check the progress") |

> Option: the details of the progress can be found by press `Show in workflow engine` or https://staging.demo.naavre.net/argowf/workflows, login required.

</div>

## <a name='Retrievetheoutputdata'></a>Retrieve the output data

In the `data` folder, you should see the result files from you workflow.
* txt file: Summary of carbon stock
* csv file: Predicted carbon stock table

You can download the file by doing right click, then pressing `download`.

![img_tutorial_07-Result.png](documentation/images/img_tutorial_07-Result.png "Result in data folder")
