import React, {Component} from 'react';
import {
  StyleSheet, 
  View, 
  Image
} from 'react-native';

import Prediction from "./Prediction";
import BndBox from "./BndBox";
import Share from "./Share";

class Preview extends Component {
  constructor(props) {
    super(props);
    this.state = {
      rects: props.rects,
      screen: props.screen,
      image: props.image,
    };
  }

  componentWillReceiveProps(nextProps) {
    const {rects, screen, image} = nextProps;
    this.setState({ rects, screen, image });  
  }

  render() {
    const {imageURI} = this.props;
    const {rects, screen, image} = this.state;

    var hotdog = rects && rects.length > 0;
    return (
      <View style={styles.container}>
        <View style={[styles.container, {justifyContent: 'center', alignItems: 'center'}]}>
          <Image
            source={{uri: imageURI}}
            style={{width: image.w, height: image.h}} 
          />
        </View>
        <BndBox rects={rects} image={image}/>
        <Prediction hotdog={hotdog} screen={screen} />
        <Share hotdog={hotdog} onClear={this.props.onClear}/>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    top: 0,
    backgroundColor: 'white',
  }
});

export default Preview;
