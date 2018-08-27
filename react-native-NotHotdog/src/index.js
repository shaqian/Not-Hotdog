import React, {Component} from 'react';
import {
  ActivityIndicator,
  Platform,
  StyleSheet,
  View, 
  NativeModules, 
  NativeEventEmitter,
  DeviceEventEmitter,
  Dimensions,
  TouchableOpacity
} from 'react-native';
import Svg,{
  Text
} from 'react-native-svg';
import { RNCamera } from 'react-native-camera';

const { TensorflowManager } = NativeModules;
const TensorflowEmitter = new NativeEventEmitter(TensorflowManager);

import Preview from "./components/Preview";

const yoloH = 416, yoloW = 416;

export default class App extends Component {
  state = {
    imageURI: undefined,
    rects: [],
    screen: {h: 0, w: 0},
    image: {h:0, w: 0},
    evaluating: false
  }

  componentWillMount() {
    var {width, height} = Dimensions.get('window');
    var screen = {w: width, h: height};
    this.setState({ screen });

    TensorflowManager.loadModel((error) => {
      if(error) {
        console.warn(error);
      }
    });
  }

  componentDidMount() {
    if (Platform.OS === 'ios') {
      TensorflowEmitter.addListener('predictions', this._handlePredictions.bind(this));
    } else {
      DeviceEventEmitter.addListener('predictions', this._handlePredictions.bind(this));
    }
  }

  _handlePredictions(event) {
    this.setState({evaluating: false});

    const {image} = this.state;
    
    var results = event;

    if (!(results && results.length > 0)) return;

    results.sort((a, b) => {
      return a.confidenceInClass < b.confidenceInClass;
    })

    var rects = [{...results[0].rect, confidence: results[0].confidenceInClass}];

    var cnt = 0;
    for (i = 1; i < results.length; i++) {
      var a = results[i].rect;
      var add = true;

      for (j = 0; j <= cnt; j++) {
        var b = rects[j];
        
        var XA1 = a.x;
        var XA2 = a.x + a.w;
        var XB1 = b.x;
        var XB2 = b.x + b.w;
        var YA1 = a.y;
        var YA2 = a.y + a.h;
        var YB1 = b.y;
        var YB2 = b.y + b.h;

        var SA = a.w * a.h;
        var SB = b.w * b.h;
        var SI = Math.max(0, Math.min(XA2, XB2) - Math.max(XA1, XB1)) * Math.max(0, Math.min(YA2, YB2) - Math.max(YA1, YB1));
        var SU = SA > SB ? SB : SA;

        var ratio = SI / SU;
        if (ratio > 0.5) {
          add = false;
        }
      }

      if (add) {
        cnt++;
        rects.push({...results[i].rect, confidence: results[i].confidenceInClass});
      }
    }

    var ratioH = image.h / yoloH;
    var ratioW = image.w / yoloW;

    rects = rects.map((rect) => {
      var newRect = {x: rect.x * ratioW, y: rect.y * ratioH, w: rect.w * ratioW, h: rect.h * ratioH, confidence: rect.confidence};
      return newRect;
    });

    this.setState({rects});
  }

  _clear() {
    this.setState({imageURI: undefined, evaluating: false});
  }

  _updateDimensions(event) {
    this._clear();
    const { height, width } = event.nativeEvent.layout;
    var screen = {w: width, h: height};
    this.setState({ screen });
  }

  render() {
    const {imageURI, evaluating, rects, screen, image} = this.state;
    return (
      <View style={styles.container} onLayout={this._updateDimensions.bind(this)}>
        <RNCamera
          ref={ref => {
            this.camera = ref;
          }}
          style = {styles.camera}
          type={RNCamera.Constants.Type.back}
          flashMode={RNCamera.Constants.FlashMode.off}
          permissionDialogTitle={'Permission to use camera'}
          permissionDialogMessage={'We need your permission to use your camera phone'}
        >
        {
          Platform.OS === "ios" && evaluating ?
          <View style={styles.evaluating}>
            <ActivityIndicator size="large" color="yellow" />
            <Svg width={screen.w} height={screen.h/3}>
              <Text
                fill="yellow"
                stroke="black"
                fontWeight="bold"
                fontSize="30"
                x={screen.w/2}
                y={screen.h/6}
                textAnchor="middle"
              >
                Evaluating
              </Text> 
            </Svg>
          </View>
          :
          <TouchableOpacity
            onPress={this.takePicture.bind(this)}
            style = {evaluating ? {} : styles.button}
          />
        }
        </RNCamera>
        {
          imageURI && !evaluating ? 
            <Preview imageURI={imageURI} rects={rects} screen={screen} image={image} onClear={this._clear.bind(this)} />
          : undefined
        }
      </View>
    );
  }

  takePicture = async function() {    
    if (this.camera) {
      this.setState({evaluating: true});

      var options = { quality: 0.5, fixOrientation: true, forceUpOrientation: true};
      const data = await this.camera.takePictureAsync(options);

      const {screen} = this.state;
      var scale = {h: data.height / screen.h, w: data.width / screen.w};
      if (scale.h / scale.w > 1)
        var image = {w: screen.w, h: screen.h * scale.h / scale.w};
      else
        var image = {w: screen.w * scale.w / scale.h, h: screen.h};

      this.setState({imageURI: data.uri, rects: [], image});
      
      TensorflowManager.recognizeImage(data.uri, (error) => {
        if(error) {
          console.warn(error);
          this._clear();
        }
      });
    }
  };
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    backgroundColor: 'black'
  },
  camera: {
    flex: 1,
    justifyContent: 'flex-end',
    alignItems: 'center'
  },
  button: {
    flex: 0,
    backgroundColor: 'yellow',
    borderRadius: 40,
    padding: 15,
    paddingHorizontal: 20,
    alignSelf: 'center',
    margin: 20,
    height: 70,
    width: 70,
    borderWidth: 5,
    borderColor: "black"
  },
  evaluating: {
    flex: 1,
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    top: 0,
    justifyContent: 'flex-end', 
    alignItems: 'center',
    backgroundColor: 'rgba(37, 213, 253, 0.5)',
  }
});
